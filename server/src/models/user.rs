use std::collections::HashSet;

use paperclip::actix::Apiv2Schema;
use rand::{distributions::Alphanumeric, thread_rng, Rng};
use serde::{Deserialize, Serialize};

// A trait that the Validate derive will impl
use validator::{Validate, ValidationError};

use crate::models::shared::UuidModel;

use super::{chat::Chat, message::Message};

#[derive(Debug, Validate, Serialize, Deserialize, Apiv2Schema, Clone, PartialEq, Eq)]
pub struct Gender {
    #[validate(range(min = 0, max = 100))]
    pub percent_male: u8,
    #[validate(range(min = 0, max = 100))]
    pub percent_female: u8,
}

#[derive(Debug, Serialize, Deserialize, Apiv2Schema, Clone, PartialEq, Eq)]
pub enum Rating {
    LikedBy(UuidModel),
    PassedBy(UuidModel),
}

#[derive(Debug, Validate, Serialize, Deserialize, Apiv2Schema, Clone, PartialEq, Eq)]
pub struct User {
    pub uuid: UuidModel,
    #[validate(length(min = 1, message = "Username must not be empty"))]
    pub username: String,
    pub password: String,
    #[validate(length(min = 1, message = "Username must not be empty"))]
    pub display_name: String,
    #[validate(custom(function = "validate_birthdate"))]
    pub birthdate: i64,
    pub gender: Gender,
    pub elo: usize,
    //this needs to be a vec, order matters
    pub ratings: Vec<Rating>,
    pub seen: HashSet<UuidModel>,
    pub preference: Preference,
    pub chats: Vec<UuidModel>,
}

impl User {
    pub fn random_user() -> (User, Vec<Chat>, Vec<Message>) {
        fn random_username() -> String {
            let mut rng = rand::thread_rng();
            let length = rng.gen_range(5..10);
            let username: String = thread_rng()
                .sample_iter(&Alphanumeric)
                .take(length)
                .map(|c| c as char)
                .collect();
            username
        }

        fn rand_range(min: u8, max: u8) -> u8 {
            let mut rng = rand::thread_rng();
            rng.gen_range(min..max)
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

        fn rand_age_range() -> (u8, u8) {
            let min_age = rand_range(18, 90);
            let max_age = rand_range(min_age + 1, 99);
            (min_age, max_age)
        }

        fn rand_gender_range() -> (u8, u8) {
            let min_gender = rand_range(0, 90);
            let max_gender = rand_range(min_gender + 1, 100);
            (min_gender, max_gender)
        }

        let age_range = rand_age_range();
        let gender_male_range = rand_gender_range();
        let gender_female_range = rand_gender_range();

        let mut chats = vec![];
        let mut chat_entities = vec![];
        let mut messages = vec![];

        for _ in 0..10 {
            let (chat, message_entities) = Chat::random_chat(UuidModel::new(), UuidModel::new());
            chats.push(chat.uuid.clone());
            chat_entities.push(chat);
            messages.extend(message_entities);
        }

        let user = User {
            uuid: UuidModel::new(),
            username: random_username(),
            display_name: random_username(),
            password: "password".to_string(),
            birthdate: rand_age_between_18_and_99(),
            gender: Gender {
                percent_female: rand_range(0, 100),
                percent_male: rand_range(0, 100),
            },
            elo: 1000,
            ratings: vec![],
            chats: chats.clone(),
            seen: HashSet::new(),
            preference: Preference {
                min_age: Some(age_range.0),
                max_age: Some(age_range.1),
                min_gender: Some(Gender {
                    percent_male: gender_male_range.0,
                    percent_female: gender_female_range.0,
                }),
                max_gender: Some(Gender {
                    percent_male: gender_male_range.1,
                    percent_female: gender_female_range.1,
                }),
            },
        };

        (user, chat_entities, messages)
    }
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

#[derive(Debug, Validate, Serialize, Deserialize, Apiv2Schema, Clone, PartialEq, Eq)]
pub struct Preference {
    pub min_age: Option<u8>,
    pub max_age: Option<u8>,
    pub max_gender: Option<Gender>,
    pub min_gender: Option<Gender>,
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
