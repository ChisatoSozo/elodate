use std::{collections::HashSet, error::Error};

use fake::Dummy;
use paperclip::actix::Apiv2Schema;
use rand::Rng;
use serde::{Deserialize, Serialize};

// A trait that the Validate derive will impl
use validator::{Validate, ValidationError};

use crate::{db::DB, models::shared::UuidModel};

use super::{chat::Chat, image::Image, rating::Rated, shared::ImageUuidModel};

#[derive(Debug, Validate, Serialize, Deserialize, Apiv2Schema, Clone, PartialEq, Eq, Dummy)]
pub struct Gender {
    #[validate(range(min = 0, max = 100))]
    #[dummy(faker = "0..100")]
    pub percent_male: u8,
    #[validate(range(min = 0, max = 100))]
    #[dummy(faker = "0..100")]
    pub percent_female: u8,
}

#[derive(Debug, Validate, Serialize, Deserialize, Apiv2Schema, Clone, PartialEq, Dummy)]
pub struct Location {
    #[dummy(faker = "45.508888")]
    pub lat: f64,
    #[dummy(faker = "-73.561668")]
    pub long: f64,
}

impl Eq for Location {}

#[derive(Debug, Validate, Serialize, Deserialize, Apiv2Schema, Clone, PartialEq, Eq, Dummy)]
pub struct UserWithImagesAndElo {
    pub user: UserPublicFields,
    pub images: Vec<Image>,
    pub elo: String,
}

#[derive(Debug, Validate, Serialize, Deserialize, Apiv2Schema, Clone, PartialEq, Eq, Dummy)]
pub struct UserWithImagesAndEloAndUuid {
    pub user: UserPublicFields,
    pub images: Vec<Image>,
    pub elo: String,
    pub uuid: UuidModel,
}

#[derive(Debug, Validate, Serialize, Deserialize, Apiv2Schema, Clone, PartialEq, Eq, Dummy)]
pub struct UserWithImages {
    pub user: UserPublicFields,
    pub images: Vec<Image>,
}

#[derive(Debug, Validate, Serialize, Deserialize, Apiv2Schema, Clone, PartialEq, Eq, Dummy)]
pub struct UserWithImagesAndPassword {
    pub user: UserPublicFields,
    pub images: Vec<Image>,
    pub password: String,
}

#[derive(Debug, Validate, Serialize, Deserialize, Clone, PartialEq, Eq, Dummy)]
pub struct User {
    pub uuid: UuidModel,
    pub hashed_password: String,
    #[dummy(faker = "800..2000")]
    pub elo: usize,
    pub ratings: Vec<Rated>,
    pub seen: HashSet<UuidModel>,
    pub chats: Vec<UuidModel>,
    pub images: Vec<ImageUuidModel>,
    pub public: UserPublicFields,
}

impl User {
    pub fn get_chats(&self, db: &mut DB) -> Result<Vec<Chat>, Box<dyn Error>> {
        let mut chats = vec![];
        for chat_uuid in self.chats.iter() {
            let chat = db.get_chat(chat_uuid)?;
            chats.push(chat);
        }
        Ok(chats)
    }
}

#[derive(Debug, Validate, Serialize, Deserialize, Apiv2Schema, Clone, PartialEq, Eq, Dummy)]
pub struct UserPublicFields {
    #[validate(length(min = 1, message = "Username must not be empty"))]
    #[dummy(faker = "fake::faker::phone_number::en::CellNumber()")]
    pub username: String,
    #[validate(length(min = 1, message = "Username must not be empty"))]
    #[dummy(faker = "fake::faker::name::en::Name()")]
    pub display_name: String,
    #[validate(custom(function = "validate_birthdate"))]
    #[dummy(faker = "rand_age_between_18_and_99()")]
    pub birthdate: i64,
    pub gender: Gender,
    pub location: Location,
    pub preference: Preference,
    #[dummy(faker = "true")]
    pub published: Option<bool>,
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

fn validate_birthdate(birthdate: i64) -> Result<(), ValidationError> {
    //use chrono to validate the birthdate as over 18 years old

    let birthdate = chrono::DateTime::from_timestamp(birthdate, 0);

    let birthdate = match birthdate {
        Some(birthdate) => birthdate,
        None => return Err(ValidationError::new("Invalid birthdate")),
    };

    let now = chrono::Utc::now();
    let min_year = now - chrono::TimeDelta::weeks(18 * 52);

    if birthdate > min_year {
        return Err(ValidationError::new("User must be over 18 years old"));
    }

    Ok(())
}

#[derive(Debug, Validate, Serialize, Deserialize, Apiv2Schema, Clone, PartialEq, Eq, Dummy)]
pub struct Preference {
    pub min_age: Option<u8>,
    pub max_age: Option<u8>,
    pub max_gender: Option<Gender>,
    pub min_gender: Option<Gender>,
    pub distance_km: Option<u8>,
}

impl Preference {
    pub fn with_defaults(&self) -> Preference {
        let mut preference = self.clone();

        if preference.min_age.is_none() {
            preference.min_age = Some(0);
        }

        if preference.max_age.is_none() {
            preference.max_age = Some(255);
        }

        if preference.max_gender.is_none() {
            preference.max_gender = Some(Gender {
                percent_male: 100,
                percent_female: 100,
            });
        }
        if preference.min_gender.is_none() {
            preference.min_gender = Some(Gender {
                percent_female: 0,
                percent_male: 0,
            });
        }

        preference
    }
}
