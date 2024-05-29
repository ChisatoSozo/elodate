use super::{api_image::ApiImageWritable, shared::ApiUuid};
use crate::{
    db::DB,
    elo::{elo_min, elo_to_label},
    models::internal_models::{
        internal_chat::InternalChat,
        internal_image::{Access, InternalImage},
        internal_prefs::{LabeledPreferenceRange, LabeledProperty, PreferenceRange, PREFS_CONFIG},
        internal_user::InternalUser,
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

#[derive(Debug, Clone, Serialize, Apiv2Schema)]
pub struct ApiUser {
    pub uuid: ApiUuid<InternalUser>,
    pub images: Vec<ApiUuid<InternalImage>>,
    pub elo: String,
    pub username: String,
    pub display_name: String,
    pub description: String,
    pub prefs: Vec<LabeledPreferenceRange>,
    pub props: Vec<LabeledProperty>,
    pub birthdate: i64,
    pub published: bool,
    pub chats: Option<Vec<ApiUuid<InternalChat>>>,
}

impl ApiUser {
    pub fn from_internal(
        user: InternalUser,
        requester: &InternalUser,
    ) -> Result<Self, Box<dyn Error>> {
        Ok(ApiUser {
            uuid: user.uuid.clone().into(),
            images: user.images.into_iter().map(|i| i.into()).collect(),
            elo: elo_to_label(user.elo),
            username: user.username,
            display_name: user.display_name,
            description: user.description,
            prefs: user.prefs,
            props: user.props,
            birthdate: user.birthdate,
            published: user.published,
            chats: if requester.uuid == user.uuid {
                Some(user.chats.into_iter().map(|c| c.into()).collect())
            } else {
                None
            },
        })
    }
}

#[derive(Debug, Clone, Deserialize, Apiv2Schema)]
pub struct ApiUserWritable {
    pub uuid: ApiUuid<InternalUser>,
    pub images: Vec<ApiUuid<InternalImage>>,
    pub username: String,
    pub password: Option<String>,
    pub display_name: String,
    pub description: String,
    pub prefs: Vec<LabeledPreferenceRange>,
    pub props: Vec<LabeledProperty>,
    pub birthdate: i64,
}

impl ApiUserWritable {
    pub fn to_internal(mut self, db: &DB) -> Result<InternalUser, Box<dyn Error>> {
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
            for image in &internal_user.images {
                image.clone().delete(db)?;
            }
        }

        let published = if let Some(internal_user) = &internal_user {
            internal_user.published
        } else {
            false
        };

        let owned_images = if let Some(internal_user) = &internal_user {
            (&internal_user).owned_images.clone()
        } else {
            vec![]
        };

        let preview_uuid: InternalUuid<_> = self.images[0].clone().into();
        let first_image = preview_uuid.load(db)?;
        let preview_image = first_image.ok_or("No preview image")?;
        let preview_image = preview_image.to_preview(Access::Everyone)?;
        let preview_image_uuid = preview_image.save(db)?;

        //fill props.additional with default values up to PREFS_CARDINALITY, from the index of the last filled value
        let last_filled = self.props.len();
        for i in last_filled..PREFS_CONFIG.len() {
            self.props.push(LabeledProperty {
                name: PREFS_CONFIG[i].name.to_string(),
                value: -32768,
            });
        }
        assert!(self.props.len() == PREFS_CONFIG.len());

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

        Ok(InternalUser {
            uuid: internal_uuid.clone(),
            hashed_password,
            elo: internal_user.as_ref().map_or(elo_min(), |u| u.elo.clone()),
            ratings: internal_user.as_ref().map_or(vec![], |u| u.ratings.clone()),
            seen: internal_user
                .as_ref()
                .map_or(vec![internal_uuid.clone()], |u| u.seen.clone()),
            chats: internal_user.as_ref().map_or(vec![], |u| u.chats.clone()),
            images: self.images.clone().into_iter().map(|i| i.into()).collect(),
            username: self.username,
            display_name: self.display_name,
            description: self.description,
            birthdate: self.birthdate,
            prefs: self.prefs,
            props: self.props,
            published: published,
            owned_images: owned_images,
            preview_image: preview_image_uuid,
        })
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
        let hashed_password = "asdfasdf".to_string();
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
            images: uuids.into_iter().map(|uuid| uuid.into()).collect(),
            password: Some(hashed_password),
        }
    }
}
