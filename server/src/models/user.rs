use crate::{
    db::{get_any_from_key, get_single_from_key},
    elo::{ELO_SCALE, ELO_SHIFT},
    models::preference::UserProperties,
    mokuroku::lib::{Document, Emitter, Error as MkrkError},
    test::fake::FakeGen,
    util::{save_as_webp, to_i16},
    vec::shared::VectorSearch,
};
use fake::Fake;
use std::{
    collections::{HashMap, HashSet},
    error::Error,
    path::Path,
};

use paperclip::actix::Apiv2Schema;
use rand::Rng;
use serde::{Deserialize, Serialize};
use validator::{Validate, ValidationError};

use super::{
    chat::Chat,
    image::Image,
    preference::{ADDITIONAL_PREFERENCES, PREFERENCE_CARDINALITY},
    rating::Rated,
    shared::ImageUuidModel,
};
use crate::models::preference::Preference;
use crate::{db::DB, models::shared::UuidModel};

#[derive(Debug, Validate, Serialize, Deserialize, Apiv2Schema, Clone, PartialEq, Eq)]
pub struct Gender {
    #[validate(range(min = 0, max = 100))]
    pub percent_male: i16,
    #[validate(range(min = 0, max = 100))]
    pub percent_female: i16,
}

impl FakeGen<bool> for Gender {
    fn fake_gen(_options: &bool) -> Self {
        let mut rng = rand::thread_rng();
        let is_male = rng.gen_bool(0.5);
        let percent_male = is_male as i16 * 100;
        let percent_female = (is_male == false) as i16 * 100;
        Gender {
            percent_male,
            percent_female,
        }
    }
}

#[derive(Debug, Validate, Serialize, Deserialize, Apiv2Schema, Clone, PartialEq)]
pub struct Location {
    pub lat: i16,
    pub long: i16,
}

impl FakeGen<bool> for Location {
    fn fake_gen(_options: &bool) -> Self {
        let lat = 45.510197;
        let long = -73.565600;
        let lati16 = to_i16(lat, -90.0, 90.0);
        let longi16 = to_i16(long, -180.0, 180.0);
        Location {
            lat: lati16,
            long: longi16,
        }
    }
}

impl Eq for Location {}

#[derive(Debug, Validate, Serialize, Deserialize, Apiv2Schema, Clone, PartialEq, Eq)]
pub struct UserWithImagesAndElo {
    pub user: UserPublicFields,
    pub images: Vec<Image>,
    pub elo: String,
}

#[derive(Debug, Validate, Serialize, Deserialize, Apiv2Schema, Clone, PartialEq, Eq)]
pub struct UserWithImagesAndEloAndUuid {
    pub user: UserPublicFields,
    pub images: Vec<Image>,
    pub elo: String,
    pub uuid: UuidModel,
}

#[derive(Debug, Validate, Serialize, Deserialize, Apiv2Schema, Clone, PartialEq, Eq)]
pub struct UserWithImages {
    pub user: UserPublicFields,
    pub images: Vec<Image>,
}

#[derive(Debug, Validate, Serialize, Deserialize, Apiv2Schema, Clone, PartialEq, Eq)]
pub struct UserWithImagesAndPassword {
    pub user: UserPublicFields,
    pub images: Vec<Image>,
    pub password: String,
}

#[derive(Debug, Validate, Serialize, Deserialize, Clone, PartialEq, Eq)]
pub struct User {
    pub uuid: UuidModel,
    pub hashed_password: String,
    pub elo: usize,
    pub ratings: Vec<Rated>,
    pub seen: HashSet<UuidModel>,
    pub chats: Vec<UuidModel>,
    pub images: Vec<ImageUuidModel>,
    pub public: UserPublicFields,
}

impl FakeGen<bool> for User {
    fn fake_gen(_options: &bool) -> Self {
        let uuid = UuidModel::new();
        let hashed_password = "asdfasdf".to_string();
        let elo = (ELO_SCALE / (ELO_SHIFT - rand::rngs::ThreadRng::default().gen_range(0.0..1.0)))
            as usize;
        let ratings = vec![];
        let seen = HashSet::new();
        let chats = vec![];
        let images = vec![];
        let public = UserPublicFields::fake_gen(&true);
        User {
            uuid,
            hashed_password,
            elo,
            ratings,
            seen,
            chats,
            images,
            public,
        }
    }
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

#[derive(Debug, Validate, Serialize, Deserialize, Apiv2Schema, Clone, PartialEq, Eq)]
pub struct UserPublicFields {
    #[validate(length(min = 1, message = "Username must not be empty"))]
    pub username: String,
    #[validate(length(min = 1, message = "Username must not be empty"))]
    pub display_name: String,
    pub description: String,
    #[validate(custom(function = "validate_birthdate"))]
    pub birthdate: i64,
    pub gender: Gender,
    pub location: Location,
    pub preference: Preference,
    pub additional_properties: HashMap<String, i16>,
    pub published: Option<bool>,
}

impl FakeGen<bool> for UserPublicFields {
    fn fake_gen(_options: &bool) -> Self {
        let mut rng = rand::thread_rng();
        let username: String = fake::faker::phone_number::en::PhoneNumber().fake();
        let display_name: String = fake::faker::name::en::Name().fake();
        let description: String = fake::faker::lorem::en::Paragraph(1..3).fake();
        let birthdate = rand_age_between_18_and_99();
        let gender = Gender::fake_gen(&true);
        let location = Location::fake_gen(&true);
        let mut additional_properties = HashMap::new();

        let mut index = 5; // Start from the 6th element in the array

        while index < PREFERENCE_CARDINALITY {
            let property = ADDITIONAL_PREFERENCES[index].sample(&mut rng);
            additional_properties.insert(ADDITIONAL_PREFERENCES[index].name.to_string(), property);
            index += 1;
        }

        let user = UserProperties {
            age: get_age(birthdate),
            percent_female: gender.percent_female,
            percent_male: gender.percent_male,
            latitude: location.lat,
            longitude: location.long,
            additional_preferences: additional_properties.clone(),
        };

        let preference = Preference::fake_gen(&user);
        let published = Some(true);
        UserPublicFields {
            username,
            display_name,
            description,
            birthdate,
            gender,
            location,
            preference,
            additional_properties,
            published,
        }
    }
}

fn get_age(birthdate: i64) -> i16 {
    let birthdate = chrono::DateTime::from_timestamp(birthdate, 0).unwrap();
    let now = chrono::Utc::now();
    let age = now - birthdate;
    (age.num_days() / 365) as i16
}

impl UserPublicFields {
    pub fn get_age(&self) -> i16 {
        get_age(self.birthdate)
    }

    pub fn to_user_properties(&self) -> UserProperties {
        UserProperties {
            age: self.get_age(),
            percent_male: self.gender.percent_female,
            percent_female: self.gender.percent_male,
            latitude: self.location.lat,
            longitude: self.location.long,
            additional_preferences: self.additional_properties.clone(),
        }
    }

    pub fn get_my_vector(&self) -> [i16; PREFERENCE_CARDINALITY] {
        self.to_user_properties().get_vector()
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

impl Document for User {
    fn from_bytes(_key: &[u8], value: &[u8]) -> Result<Self, MkrkError> {
        let serde_result: User =
            serde_cbor::from_slice(value).map_err(|err| MkrkError::Serde(format!("{}", err)))?;
        Ok(serde_result)
    }

    fn to_bytes(&self) -> Result<Vec<u8>, MkrkError> {
        let encoded: Vec<u8> =
            serde_cbor::to_vec(self).map_err(|err| MkrkError::Serde(format!("{}", err)))?;
        Ok(encoded)
    }

    fn map(&self, view: &str, emitter: &Emitter) -> Result<(), MkrkError> {
        match view {
            "uuid" => {
                let bytes = self.uuid.0.as_bytes();
                emitter.emit(bytes, None)?;
            }
            "username" => {
                let bytes = self.public.username.as_bytes();
                emitter.emit(bytes, None)?;
            }
            _ => {}
        }
        Ok(())
    }
}

impl DB {
    pub fn insert_user(&mut self, user: &User) -> Result<(), MkrkError> {
        let key = &user.uuid.0;
        let key = b"user/"
            .to_vec()
            .into_iter()
            .chain(key.as_bytes().to_vec().into_iter())
            .collect::<Vec<u8>>();
        self.db.put(key, user)?;
        self.vec_index
            .add(&user.public.get_my_vector(), &user.uuid.0);
        self.vec_index
            .add_bbox(&user.public.preference.get_bbox(), &user.uuid.0);
        Ok(())
    }

    pub fn get_user_by_uuid(&mut self, uuid: &UuidModel) -> Result<User, MkrkError> {
        let result = get_single_from_key("uuid", uuid.0.as_bytes(), &mut self.db)?;
        Ok(result)
    }

    pub fn user_with_username_exists(&mut self, username: &str) -> Result<bool, MkrkError> {
        let result: Vec<User> = get_any_from_key("username", username.as_bytes(), &mut self.db)?;
        Ok(!result.is_empty())
    }

    pub fn get_images_from_user(
        &mut self,
        user: &UuidModel,
    ) -> Result<Vec<Image>, Box<dyn std::error::Error>> {
        let user = self.get_user_by_uuid(user)?;
        let images = user.images;
        let mut images_out = Vec::new();
        for image_id in images {
            let path = Image::get_user_image_path(&user.uuid, &image_id, &self);
            let image = Image::load(path)?;
            images_out.push(image);
        }
        Ok(images_out)
    }

    pub fn get_image_from_user(
        &mut self,
        user: &UuidModel,
    ) -> Result<Image, Box<dyn std::error::Error>> {
        let user = self.get_user_by_uuid(user)?;
        let first_image = user.images.first().unwrap();
        let path = Image::get_user_image_path(&user.uuid, first_image, &self);
        let image = Image::load(path)?;
        Ok(image)
    }

    pub fn add_images_to_user(
        &mut self,
        user_id: &UuidModel,
        images: &Vec<Image>,
    ) -> Result<Vec<ImageUuidModel>, Box<dyn std::error::Error>> {
        let mut uuids = Vec::new();
        for image in images {
            let image_uuid = ImageUuidModel {
                uuid: UuidModel::new(),
                image_type: image.image_type.clone(),
            };
            let path_str = Image::get_user_image_path(user_id, &image_uuid, &self);
            let path = Path::new(&path_str);
            let path_dir_without_image = path.parent().unwrap();
            //create directory recursively if it doesn't exist
            std::fs::create_dir_all(&path_dir_without_image)?;

            save_as_webp(&image.b64_content, &image.image_type, Path::new(&path))?;

            uuids.push(image_uuid);
        }

        Ok(uuids)
    }

    pub fn get_user_by_username(&mut self, username: &str) -> Result<User, MkrkError> {
        let result = get_single_from_key("username", username.as_bytes(), &mut self.db)?;
        Ok(result)
    }
}
