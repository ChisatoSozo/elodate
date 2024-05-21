use crate::{
    elo::{ELO_SCALE, ELO_SHIFT},
    util::to_i16,
};

use fake::Fake;
use std::error::Error;

use rand::Rng;

//TODO: recalc age on day change

use super::{
    internal_chat::InternalChat,
    internal_image::InternalImage,
    internal_preferences::{
        LabeledPreferenceRange, LabeledProperty, Preferences, Properties,
        ADDITIONAL_PREFERENCES_CONFIG, MANDATORY_PREFERENCES_CONFIG,
    },
    shared::{Gen, InternalUuid, Save},
};

use crate::db::DB;

#[derive(Debug, Clone, rkyv::Serialize, rkyv::Deserialize, rkyv::Archive)]
#[archive(compare(PartialEq), check_bytes)]
pub enum InternalRating {
    LikedBy(InternalUuid<InternalUser>),
    PassedBy(InternalUuid<InternalUser>),
}

#[derive(Debug, Clone, rkyv::Serialize, rkyv::Deserialize, rkyv::Archive)]
#[archive(compare(PartialEq), check_bytes)]
pub struct InternalUser {
    pub uuid: InternalUuid<InternalUser>,
    pub hashed_password: String,
    pub elo: u32,
    pub ratings: Vec<InternalRating>,
    pub seen: Vec<InternalUuid<InternalUser>>,
    pub chats: Vec<InternalUuid<InternalChat>>,
    pub images: Vec<InternalUuid<InternalImage>>,
    pub username: String,
    pub display_name: String,
    pub description: String,
    pub birthdate: i64,
    pub preferences: Preferences,
    pub properties: Properties,
    pub published: bool,
}

impl InternalUser {
    pub fn is_liked_by(&self, user: &InternalUuid<InternalUser>) -> bool {
        self.ratings.iter().any(|rating| match rating {
            InternalRating::LikedBy(uuid) => uuid == user,
            _ => false,
        })
    }

    pub fn add_chat(&mut self, chat: &InternalChat) {
        self.chats.push(chat.uuid.clone());
    }

    pub fn get_chats(&self, db: &DB) -> Result<Vec<InternalChat>, Box<dyn Error>> {
        let mut chats = vec![];
        for chat_uuid in self.chats.iter() {
            let chat = chat_uuid.load(db)?;
            let chat = match chat {
                Some(chat) => chat,
                None => return Err("Chat not found".into()),
            };
            chats.push(chat);
        }
        Ok(chats)
    }
}

impl Save for InternalUser {
    fn save(self, db: &DB) -> Result<InternalUuid<InternalUser>, Box<dyn Error>> {
        db.write_index("user.username", &self.username, &self.uuid)?;
        db.write_object(&self.uuid, &self)
    }
}

impl Gen<DB> for InternalUser {
    fn gen(db: &DB) -> Self {
        let mut rng = rand::thread_rng();
        let uuid = InternalUuid::<InternalUser>::new();
        let hashed_password = "asdfasdf".to_string();
        let elo =
            (ELO_SCALE / (ELO_SHIFT - rand::rngs::ThreadRng::default().gen_range(0.0..1.0))) as u32;
        let ratings = vec![];
        let seen = vec![];
        let chats = vec![];
        let image = InternalImage::gen(&true);
        let img_uuid = image.save(db).unwrap();
        let images = vec![img_uuid];
        let is_male = rng.gen_bool(0.5);
        let percent_male = is_male as i16 * 100;
        let percent_female = (is_male == false) as i16 * 100;
        let username = fake::faker::phone_number::en::PhoneNumber().fake();
        let display_name = fake::faker::name::en::Name().fake();
        let description = fake::faker::lorem::en::Paragraph(1..3).fake();
        let birthdate = rand_age_between_18_and_99();
        let latitude = rng.gen_range(-90.0..90.0);
        let latitudei16 = to_i16(latitude, -90.0, 90.0);
        let longitude = rng.gen_range(-180.0..180.0);
        let longitudei16 = to_i16(longitude, -180.0, 180.0);
        let properties = Properties {
            age: get_age(birthdate),
            percent_male,
            percent_female,
            latitude: latitudei16,
            longitude: longitudei16,
            additional_properties: ADDITIONAL_PREFERENCES_CONFIG
                .iter()
                .map(|config| LabeledProperty {
                    name: config.name.to_string(),
                    value: config.sample(&mut rng),
                })
                .collect(),
        };
        let preferences = Preferences {
            age: MANDATORY_PREFERENCES_CONFIG
                .age
                .sample_range(&properties, &mut rng),
            percent_male: MANDATORY_PREFERENCES_CONFIG
                .percent_male
                .sample_range(&properties, &mut rng),
            percent_female: MANDATORY_PREFERENCES_CONFIG
                .percent_female
                .sample_range(&properties, &mut rng),
            latitude: MANDATORY_PREFERENCES_CONFIG
                .latitude
                .sample_range(&properties, &mut rng),
            longitude: MANDATORY_PREFERENCES_CONFIG
                .longitude
                .sample_range(&properties, &mut rng),
            additional_preferences: ADDITIONAL_PREFERENCES_CONFIG
                .iter()
                .map(|config| LabeledPreferenceRange {
                    name: config.name.to_string(),
                    range: config.sample_range(&properties, &mut rng),
                })
                .collect(),
        };

        InternalUser {
            uuid,
            hashed_password,
            elo,
            ratings,
            seen,
            chats,
            images,
            username,
            display_name,
            description,
            birthdate,
            preferences,
            properties,
            published: true,
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

impl DB {
    pub fn get_user_by_username(
        &self,
        username: &String,
    ) -> Result<Option<InternalUser>, Box<dyn Error>> {
        let uuid = self.read_index::<InternalUser>("user.username", username)?;
        match uuid {
            Some(uuid) => uuid.load(self),
            None => Err("User not found".into()),
        }
    }
}
