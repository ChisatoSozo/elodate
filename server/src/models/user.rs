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
    #[dummy(faker = "fake::faker::lorem::en::Paragraph(3..4)")]
    pub description: String,
    #[validate(custom(function = "validate_birthdate"))]
    #[dummy(faker = "rand_age_between_18_and_99()")]
    pub birthdate: i64,
    pub gender: Gender,
    pub location: Location,
    pub preference: Preference,
    #[dummy(faker = "true")]
    pub published: Option<bool>,
}
impl UserPublicFields {
    pub fn get_age(&self) -> Option<i64> {
        let birthdate = chrono::DateTime::from_timestamp(self.birthdate, 0)?;
        let now = chrono::Utc::now();
        let age = now - birthdate;
        Some(age.num_days() / 365)
    }

    pub fn get_preference_min_vector(&self) -> Vec<u16> {
        vec![
            self.preference.age.min,
            self.preference.percent_female.min,
            self.preference.percent_male.min,
        ]
    }

    pub fn get_preference_max_vector(&self) -> Vec<u16> {
        vec![
            self.preference.age.max,
            self.preference.percent_female.max,
            self.preference.percent_female.max,
        ]
    }

    pub fn get_my_vector(&self) -> Vec<u16> {
        vec![
            self.get_age().unwrap() as u16,
            self.gender.percent_female as u16,
            self.gender.percent_male as u16,
        ]
    }
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
pub struct PreferenceRange {
    #[dummy(faker = "0")]
    pub min: u16,
    #[dummy(faker = "65536")]
    pub max: u16,
}

impl Default for PreferenceRange {
    fn default() -> Self {
        Self { min: 0, max: 65535 }
    }
}

#[derive(
    Debug, Validate, Serialize, Deserialize, Apiv2Schema, Clone, PartialEq, Eq, Dummy, Default,
)]
pub struct Preference {
    pub age: PreferenceRange,
    pub percent_male: PreferenceRange,
    pub percent_female: PreferenceRange,
    pub latitude: PreferenceRange,
    pub longitude: PreferenceRange,
}
