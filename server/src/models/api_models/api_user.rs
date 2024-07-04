use super::{api_image::ApiImageWritable, shared::ApiUuid};
use crate::{
    db::DB,
    elo::elo_to_label,
    models::internal_models::{
        internal_chat::InternalChat,
        internal_image::{Access, InternalImage},
        internal_prefs::{LabeledPreferenceRange, LabeledProperty, PreferenceRange},
        internal_prefs_config::PREFS_CONFIG,
        internal_user::{BotProps, InternalUser, Notification},
        shared::{InternalUuid, Save},
    },
    test::fake::Gen,
    util::to_i16,
};
use bcrypt::hash;
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
            images: user.images.into_iter().map(|i| i.into()).collect(),
            preview_image: user.preview_image.map(|i| i.into()),
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
                Some(user.chats.into_iter().map(|c| c.into()).collect())
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
    pub fn to_internal(mut self, db: &DB, published: bool) -> Result<InternalUser, Box<dyn Error>> {
        self.fill_prefs();
        self.fill_props();
        let internal_uuid: InternalUuid<InternalUser> = self.uuid.into();
        let internal_user = internal_uuid.load(db)?;

        let hashed_password = if let Some(internal_user) = &internal_user {
            internal_user.hashed_password.clone()
        } else if let Some(password) = self.password {
            hash(password, 4)?
        } else {
            return Err("No password for no internal user".into());
        };

        if let Some(internal_user) = &internal_user {
            let old_images = internal_user.images.clone();
            for image in old_images {
                //if the image is not in the new images, delete it
                if !self.images.contains(&image.clone().into()) {
                    let loaded = image.load(db)?;
                    match loaded {
                        Some(image) => {
                            image.uuid.delete(db)?;
                        }
                        None => {
                            return Err(
                                "Image not found, can't delete, this shouldn't happen".into()
                            )
                        }
                    }
                }
            }
        }

        let owned_images = if let Some(internal_user) = &internal_user {
            (&internal_user).owned_images.clone()
        } else {
            vec![]
        };

        //fill props.additional with default values up to PREFS_CARDINALITY, from the index of the last filled value

        assert!(self.props.len() == PREFS_CONFIG.len());
        assert!(self.prefs.len() == PREFS_CONFIG.len());

        //do you have access to all the images you're trying to add?
        for image in &self.images {
            let image_uuid: InternalUuid<InternalImage> = image.clone().into();
            let loaded = image_uuid.load(db)?;
            match loaded {
                Some(image) => {
                    if !image.access.can_access(&internal_uuid) {
                        return Err("No access to image".into());
                    }
                }
                None => return Err("Image not found".into()),
            }
        }

        //do you have access to the preview image you're trying to add?
        if let Some(preview_image) = &self.preview_image {
            let image_uuid: InternalUuid<InternalImage> = preview_image.clone().into();
            let loaded = image_uuid.load(db)?;
            match loaded {
                Some(image) => {
                    if !image.access.can_access(&internal_uuid) {
                        return Err("No access to image".into());
                    }
                }
                None => return Err("Image not found".into()),
            }
        }

        let mut bot_props = None;
        if self.is_bot && internal_user.is_none() {
            bot_props = Some(BotProps::gen());
        }

        let (elo, ratings, seen, chats, actions, notifications, is_admin) =
            if let Some(internal_user) = internal_user {
                // If we have an internal_user, use its bot_props if our initial bot_props is None
                if bot_props.is_none() {
                    bot_props = internal_user.bot_props;
                }
                (
                    internal_user.elo,
                    internal_user.ratings,
                    internal_user.seen,
                    internal_user.chats,
                    internal_user.actions,
                    internal_user.notifications,
                    internal_user.is_admin,
                )
            } else {
                (
                    0.0,
                    vec![],
                    vec![internal_uuid.clone()],
                    vec![],
                    vec![],
                    vec![],
                    false,
                )
            };

        //set age
        let age_index = self
            .props
            .iter()
            .position(|p| p.name == "age")
            .ok_or("No age")?;
        self.props[age_index].value = get_age(self.birthdate);

        Ok(InternalUser {
            uuid: internal_uuid.clone(),
            hashed_password,
            elo,
            ratings,
            seen,
            chats,
            images: self.images.clone().into_iter().map(|i| i.into()).collect(),
            username: self.username,
            display_name: self.display_name,
            description: self.description,
            birthdate: self.birthdate,
            prefs: self.prefs,
            props: self.props,
            published,
            owned_images,
            preview_image: self.preview_image.map(|i| i.into()),
            actions,
            notifications,
            is_admin,
            bot_props,
        })
    }

    pub fn fill_props(&mut self) {
        //fill props.additional with default values up to PREFS_CARDINALITY, from the index of the last filled value
        let last_filled = self.props.len();
        for i in last_filled..PREFS_CONFIG.len() {
            let pref = &PREFS_CONFIG[i];
            if let Some(default) = pref.default {
                self.props.push(LabeledProperty {
                    name: pref.name.to_string(),
                    value: default,
                });
            } else {
                self.props.push(LabeledProperty {
                    name: PREFS_CONFIG[i].name.to_string(),
                    value: -32768,
                });
            }
        }
    }

    pub fn fill_prefs(&mut self) {
        //fill prefs.additional with default values up to PREFS_CARDINALITY, from the index of the last filled value
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
    let birthdate = chrono::DateTime::from_timestamp(birthdate, 0).unwrap();
    let now = chrono::Utc::now();
    let age = now - birthdate;
    (age.num_days() / 365) as i16
}

fn rand_date_between(min: i64, max: i64) -> i64 {
    let mut rng = rand::thread_rng();
    rng.gen_range(min..max)
}

fn rand_age_between_18_and_99() -> i64 {
    let now = chrono::Utc::now();
    let min_year = now - chrono::TimeDelta::weeks(99 * 52);
    let max_year = now - chrono::TimeDelta::weeks(18 * 52);
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
        let percent_female = (is_male == false) as i16 * 100;
        let username = fake::faker::phone_number::en::PhoneNumber().fake();
        let display_name = fake::faker::name::en::Name().fake();
        let description = fake::faker::lorem::en::Paragraph(1..3).fake();
        let birthdate = rand_age_between_18_and_99();
        // let latitude = rng.gen_range(-90.0..90.0);
        let latitude = 45.501690;
        let latitudei16 = to_i16(latitude, -90.0, 90.0);
        // let longitude = rng.gen_range(-180.0..180.0);
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
            images: uuids.clone().into_iter().map(|uuid| uuid.into()).collect(),
            preview_image: uuids.first().map(|uuid| uuid.clone().into()),
            password: Some(password),
            is_bot: true,
        }
    }
}
