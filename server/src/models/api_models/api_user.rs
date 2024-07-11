use super::{api_image::ApiImageWritable, shared::ApiUuid};
use crate::{
    db::DB,
    elo::elo_to_label,
    models::internal_models::{
        internal_chat::InternalChat,
        internal_image::{Access, InternalImage},
        internal_prefs::{LabeledPreferenceRange, LabeledProperty, PreferenceRange},
        internal_prefs_config::PREFS_CONFIG,
        internal_user::{BotProps, InternalRating, InternalUser, Notification, TimestampedAction},
        migration::migration::get_admin_uuid,
        shared::{InternalUuid, Save},
    },
    test::fake::Gen,
    util::to_i16,
};
use bcrypt::{hash, DEFAULT_COST};
use chrono::{DateTime, TimeDelta, Utc};
use fake::Fake;
use paperclip::actix::Apiv2Schema;
use rand::Rng;
use serde::{Deserialize, Serialize};
use std::error::Error;

#[derive(Debug, Serialize, Deserialize, Apiv2Schema)]
pub struct ApiUser {
    pub uuid: ApiUuid<InternalUser>,
    pub images: Vec<ApiUuid<InternalImage>>,
    pub elo: String,
    pub elo_num: f32,
    pub username: String,
    pub display_name: String,
    pub description: String,
    pub prefs: Vec<LabeledPreferenceRange>,
    pub props: Vec<LabeledProperty>,
    pub birthdate: i64,
    pub published: bool,
    pub preview_image: Option<ApiUuid<InternalImage>>,
    pub chats: Option<Vec<ApiUuid<InternalChat>>>,
}

#[derive(Debug, Serialize, Apiv2Schema)]
pub enum ApiNotificationType {
    UnreadMessage,
    Match,
    System,
}

#[derive(Debug, Serialize, Apiv2Schema)]
pub struct ApiNotification {
    notification_type: ApiNotificationType,
    message_or_uuid: String,
}

impl From<Notification> for ApiNotification {
    fn from(notification: Notification) -> Self {
        match notification {
            Notification::UnreadMessage(uuid) => ApiNotification {
                notification_type: ApiNotificationType::UnreadMessage,
                message_or_uuid: uuid.id,
            },
            Notification::Match(uuid) => ApiNotification {
                notification_type: ApiNotificationType::Match,
                message_or_uuid: uuid.id,
            },
            Notification::System(message) => ApiNotification {
                notification_type: ApiNotificationType::System,
                message_or_uuid: message,
            },
        }
    }
}

impl ApiUser {
    pub fn from_internal(
        user: InternalUser,
        requester: Option<&InternalUser>,
    ) -> Result<Self, Box<dyn Error>> {
        Ok(ApiUser {
            uuid: user.uuid.clone().into(),
            images: user.images.into_iter().map(Into::into).collect(),
            preview_image: user.preview_image.map(Into::into),
            elo: elo_to_label(user.elo),
            elo_num: user.elo,
            username: user.username,
            display_name: user.display_name,
            description: user.description,
            prefs: user.prefs,
            props: user.props,
            birthdate: user.birthdate,
            published: user.published,
            chats: if requester.map_or(true, |r| r.uuid == user.uuid) {
                Some(user.chats.into_iter().map(Into::into).collect())
            } else {
                None
            },
        })
    }
}

#[derive(Debug, Deserialize, Apiv2Schema)]
pub struct ApiUserWritable {
    pub uuid: ApiUuid<InternalUser>,
    pub images: Vec<ApiUuid<InternalImage>>,
    pub preview_image: Option<ApiUuid<InternalImage>>,
    pub username: String,
    pub password: Option<String>,
    pub display_name: String,
    pub description: String,
    pub prefs: Vec<LabeledPreferenceRange>,
    pub props: Vec<LabeledProperty>,
    pub birthdate: i64,
    pub is_bot: bool,
}

impl ApiUserWritable {
    pub fn is_admin(&self) -> bool {
        self.uuid == get_admin_uuid().into()
    }

    pub fn to_internal(mut self, db: &DB, published: bool) -> Result<InternalUser, Box<dyn Error>> {
        self.fill_prefs();
        self.fill_props();
        let is_admin = self.is_admin();
        let internal_uuid: InternalUuid<InternalUser> = self.uuid.id.clone().into();
        let internal_user = internal_uuid.load(db)?;

        let hashed_password = if let Some(internal_user) = &internal_user {
            internal_user.hashed_password.clone()
        } else if let Some(password) = &self.password {
            hash(password, DEFAULT_COST)?
        } else {
            return Err("No password for no internal user".into());
        };

        self.handle_image_updates(db, &internal_user)?;

        let owned_images = internal_user
            .as_ref()
            .map(|user| user.owned_images.clone())
            .unwrap_or_default();

        self.validate_props_and_prefs()?;
        self.validate_image_access(db, &internal_uuid)?;

        let (elo, ratings, seen, mut chats, actions, notifications) =
            self.get_user_data(&internal_user);

        let bot_props = if self.is_bot && internal_user.is_none() {
            Some(BotProps::gen())
        } else {
            internal_user
                .as_ref()
                .and_then(|user| user.bot_props.clone())
        };

        self.set_age();

        if chats.is_empty() && !is_admin {
            let mut admin = db.get_admin()?;
            let mut admin_chats = admin.chats;
            self.create_admin_chat(db, &internal_uuid, &mut chats, &mut admin_chats)?;
            admin.chats = admin_chats;
            admin.save(db)?;
        }

        Ok(InternalUser {
            uuid: internal_uuid,
            hashed_password,
            elo,
            ratings,
            seen,
            chats,
            images: self.images.into_iter().map(Into::into).collect(),
            username: self.username,
            display_name: self.display_name,
            description: self.description,
            birthdate: self.birthdate,
            prefs: self.prefs,
            props: self.props,
            published,
            owned_images,
            preview_image: self.preview_image.map(Into::into),
            actions,
            notifications,
            bot_props,
        })
    }

    fn handle_image_updates(
        &self,
        db: &DB,
        internal_user: &Option<InternalUser>,
    ) -> Result<(), Box<dyn Error>> {
        if let Some(internal_user) = internal_user {
            let old_images = internal_user.images.clone();
            for image in old_images {
                if !self.images.contains(&image.clone().into()) {
                    if let Some(image) = image.load(db)? {
                        image.uuid.delete(db)?;
                    } else {
                        return Err("Image not found, can't delete, this shouldn't happen".into());
                    }
                }
            }
        }
        Ok(())
    }

    fn validate_props_and_prefs(&self) -> Result<(), Box<dyn Error>> {
        if self.props.len() != PREFS_CONFIG.len() || self.prefs.len() != PREFS_CONFIG.len() {
            return Err("Invalid number of props or prefs".into());
        }
        Ok(())
    }

    fn validate_image_access(
        &self,
        db: &DB,
        internal_uuid: &InternalUuid<InternalUser>,
    ) -> Result<(), Box<dyn Error>> {
        for image in &self.images {
            let image_uuid: InternalUuid<InternalImage> = image.clone().into();
            if let Some(image) = image_uuid.load(db)? {
                if !image.access.can_access(internal_uuid) {
                    return Err("No access to image".into());
                }
            } else {
                return Err("Image not found".into());
            }
        }

        if let Some(preview_image) = &self.preview_image {
            let image_uuid: InternalUuid<InternalImage> = preview_image.clone().into();
            if let Some(image) = image_uuid.load(db)? {
                if !image.access.can_access(internal_uuid) {
                    return Err("No access to preview image".into());
                }
            } else {
                return Err("Preview image not found".into());
            }
        }

        Ok(())
    }

    fn get_user_data(
        &self,
        internal_user: &Option<InternalUser>,
    ) -> (
        f32,
        Vec<InternalRating>,
        Vec<InternalUuid<InternalUser>>,
        Vec<InternalUuid<InternalChat>>,
        Vec<TimestampedAction>,
        Vec<Notification>,
    ) {
        if let Some(internal_user) = internal_user {
            (
                internal_user.elo,
                internal_user.ratings.clone(),
                internal_user.seen.clone(),
                internal_user.chats.clone(),
                internal_user.actions.clone(),
                internal_user.notifications.clone(),
            )
        } else {
            (
                0.0,
                vec![],
                vec![self.uuid.clone().into()],
                vec![],
                vec![],
                vec![],
            )
        }
    }

    fn set_age(&mut self) {
        if let Some(age_index) = self.props.iter().position(|p| p.name == "age") {
            self.props[age_index].value = get_age(self.birthdate);
        }
    }

    fn create_admin_chat(
        &self,
        db: &DB,
        internal_uuid: &InternalUuid<InternalUser>,
        user_chats: &mut Vec<InternalUuid<InternalChat>>,
        admin_chats: &mut Vec<InternalUuid<InternalChat>>,
    ) -> Result<(), Box<dyn Error>> {
        println!("Creating admin chat for {:?}", internal_uuid);
        let (chat, message) = InternalChat::new_admin_chat(internal_uuid);
        let chat_uuid = chat.save(db)?;
        if let Some(mut chat) = chat_uuid.load(db)? {
            message
                .into_internal(&get_admin_uuid(), &chat, db)?
                .save(&mut chat, db)?;
            user_chats.push(chat_uuid.clone().into());
            admin_chats.push(chat_uuid.clone().into());
            Ok(())
        } else {
            Err("Failed to load chat".into())
        }
    }

    pub fn fill_props(&mut self) {
        let last_filled = self.props.len();
        for i in last_filled..PREFS_CONFIG.len() {
            let pref = &PREFS_CONFIG[i];
            self.props.push(LabeledProperty {
                name: pref.name.to_string(),
                value: pref.default.unwrap_or(-32768),
            });
        }
    }

    pub fn fill_prefs(&mut self) {
        let last_filled = self.prefs.len();
        for i in last_filled..PREFS_CONFIG.len() {
            self.prefs.push(LabeledPreferenceRange {
                name: PREFS_CONFIG[i].name.to_string(),
                range: PreferenceRange {
                    min: -32768,
                    max: 32767,
                },
            });
        }
    }
}

fn get_age(birthdate: i64) -> i16 {
    let birthdate = DateTime::from_timestamp(birthdate, 0).unwrap();
    let now = Utc::now();
    let age = now - birthdate;
    (age.num_days() / 365) as i16
}

fn rand_date_between(min: i64, max: i64) -> i64 {
    rand::thread_rng().gen_range(min..max)
}

fn rand_age_between_18_and_99() -> i64 {
    let now = Utc::now();
    let min_year = now - TimeDelta::weeks(99 * 52);
    let max_year = now - TimeDelta::weeks(18 * 52);
    rand_date_between(min_year.timestamp(), max_year.timestamp())
}

impl Gen<'_, DB> for ApiUserWritable {
    fn gen(db: &DB) -> Self {
        let mut rng = rand::thread_rng();
        let password = "asdfasdf".to_string();
        let mut uuids = Vec::with_capacity(6);
        for _ in 0..2 {
            let image = ApiImageWritable::gen(&true)
                .to_internal(Access::Everyone)
                .unwrap();
            let img_uuid = image.save(db).unwrap();
            uuids.push(img_uuid);
        }

        let is_male = rng.gen_bool(0.5);
        let percent_male = is_male as i16 * 100;
        let percent_female = (!is_male) as i16 * 100;
        let username = fake::faker::phone_number::en::PhoneNumber().fake();
        let display_name = fake::faker::name::en::Name().fake();
        let description = fake::faker::lorem::en::Paragraph(1..3).fake();
        let birthdate = rand_age_between_18_and_99();
        let latitude = 45.501690;
        let latitudei16 = to_i16(latitude, -90.0, 90.0);
        let longitude = -73.567253;
        let longitudei16 = to_i16(longitude, -180.0, 180.0);
        let mut props = PREFS_CONFIG
            .iter()
            .map(|config| LabeledProperty {
                name: config.name.to_string(),
                value: config.sample(&mut rng),
            })
            .collect::<Vec<_>>();

        props[0].value = get_age(birthdate);
        props[1].value = percent_male;
        props[2].value = percent_female;
        props[3].value = latitudei16;
        props[4].value = longitudei16;

        let prefs = PREFS_CONFIG
            .iter()
            .map(|config| LabeledPreferenceRange {
                name: config.name.to_string(),
                range: config.sample_range(&props, &mut rng),
            })
            .collect();

        ApiUserWritable {
            username,
            display_name,
            description,
            birthdate,
            prefs,
            props,
            uuid: ApiUuid::<InternalUser>::new(),
            images: uuids.iter().cloned().map(Into::into).collect(),
            preview_image: uuids.first().cloned().map(Into::into),
            password: Some(password),
            is_bot: true,
        }
    }
}
