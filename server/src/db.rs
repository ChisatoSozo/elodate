use std::{collections::HashSet, path::Path};

use std::io::Read;

use crate::{
    models::{
        access_code::AccessCode,
        chat::Chat,
        image::{ElodateImageFormat, Image},
        message::Message,
        shared::UuidModel,
        user::User,
    },
    mokuroku::{
        base32,
        lib::{Database, Document, Emitter, Error},
    },
    util::save_as_webp,
};

pub struct DB {
    db: Database,
}

pub fn get_single_from_key<T: Document>(
    view: &str,
    key: &[u8],
    db: &mut Database,
) -> Result<T, Error> {
    //key to doc_id parse
    let doc_id = {
        let mut result = db.query_exact(view, key)?;
        let first = result.next();
        match first {
            Some(result) => Ok(result.doc_id),
            None => Err(Error::Serde("No document found".to_owned())),
        }
    }?;
    let document: Option<T> = db.get(doc_id)?;
    match document {
        Some(document) => Ok(document),
        None => Err(Error::Serde("No document found".to_owned())),
    }
}

pub fn get_any_from_key<T: Document>(
    view: &str,
    key: &[u8],
    db: &mut Database,
) -> Result<Vec<T>, Error> {
    //key to doc_id parse
    let doc_ids = {
        let mut result = db.query_exact(view, key)?;
        let mut doc_ids = Vec::new();
        while let Some(document) = result.next() {
            doc_ids.push(document.doc_id);
        }
        doc_ids
    };
    let mut documents = Vec::new();
    for doc_id in doc_ids {
        let document: Option<T> = db.get(doc_id)?;
        match document {
            Some(document) => documents.push(document),
            None => {}
        }
    }
    Ok(documents)
}

pub fn get_documents_in_range(
    view: &str,
    from: &[u8],
    to: &[u8],
    db: &mut Database,
) -> Result<HashSet<Box<[u8]>>, Error> {
    let mut result = db.query_range(view, &base32::encode(from), &base32::encode(to))?;
    let mut documents = HashSet::new();
    while let Some(document) = result.next() {
        documents.insert(document.doc_id);
    }
    Ok(documents)
}

pub fn get_documents_above(
    view: &str,
    from: &[u8],
    db: &mut Database,
) -> Result<HashSet<Box<[u8]>>, Error> {
    let mut result = db.query_greater_than(view, from)?;
    let mut documents = HashSet::new();
    while let Some(document) = result.next() {
        documents.insert(document.value);
    }
    Ok(documents)
}

pub fn get_documents_below(
    view: &str,
    to: &[u8],
    db: &mut Database,
) -> Result<HashSet<Box<[u8]>>, Error> {
    let mut result = db.query_less_than(view, to)?;
    let mut documents = HashSet::new();
    while let Some(document) = result.next() {
        documents.insert(document.doc_id);
    }
    Ok(documents)
}

impl DB {
    pub fn new(path: &str) -> Self {
        println!("Opening database");
        let db_path = "db/".to_owned() + path;
        let views: Vec<String> = VIEWS.to_vec().into_iter().map(|s| s.to_owned()).collect();
        let dbase = Database::open_default(Path::new(&db_path), views, Box::new(mapper)).unwrap();
        DB { db: dbase }
    }

    pub fn destroy_database_for_real_dangerous(path: &str) {
        //does the path exist?
        if !Path::new(&("db/".to_owned() + path)).exists() {
            return;
        }
        std::fs::remove_dir_all("db/".to_owned() + path).unwrap();
    }

    pub fn get_flag(&self, key: &str) -> bool {
        let key = b"flag/"
            .to_vec()
            .into_iter()
            .chain(key.as_bytes().to_vec().into_iter())
            .collect::<Vec<u8>>();
        let result = self.db.db.get(key);
        match result {
            Ok(Some(_)) => true,
            Ok(None) => false,
            Err(_) => false,
        }
    }

    pub fn set_flag(&mut self, key_in: &str, value: bool) {
        let key = b"flag/"
            .to_vec()
            .into_iter()
            .chain(key_in.as_bytes().to_vec().into_iter())
            .collect::<Vec<u8>>();
        if value {
            self.db.db.put(key, "t").unwrap();
        } else {
            if self.get_flag(key_in) {
                self.db.db.delete(key).unwrap();
            }
        }
    }

    pub fn insert_user(&mut self, user: &User) -> Result<(), Error> {
        let key = &user.uuid.0;
        //prepend "user/" to the key
        let key = b"user/"
            .to_vec()
            .into_iter()
            .chain(key.as_bytes().to_vec().into_iter())
            .collect::<Vec<u8>>();
        self.db.put(key, user)?;
        Ok(())
    }

    pub fn insert_chat(&mut self, chat: &Chat) -> Result<(), Error> {
        let key = &chat.uuid.0;
        //prepend "chat/" to the key
        let key = "chat/".to_string() + key;
        self.db.put(key, chat)?;
        Ok(())
    }

    pub fn get_chat(&mut self, chat_uuid: &UuidModel) -> Result<Chat, Error> {
        let result = get_single_from_key("uuid", chat_uuid.0.as_bytes(), &mut self.db)?;
        Ok(result)
    }

    pub fn insert_message(&mut self, message: &Message) -> Result<(), Error> {
        let key = &message.uuid.0;
        //prepend "message/" to the key
        let key = "message/".to_string() + key;
        self.db.put(key, message)?;

        Ok(())
    }

    pub fn get_message(&mut self, message_uuid: &UuidModel) -> Result<Message, Error> {
        let result = get_single_from_key("uuid", message_uuid.0.as_bytes(), &mut self.db)?;
        Ok(result)
    }

    pub fn get_user_by_username(&mut self, username: &str) -> Result<User, Error> {
        let result = get_single_from_key("username", username.as_bytes(), &mut self.db)?;
        Ok(result)
    }

    pub fn user_with_username_exists(&mut self, username: &str) -> Result<bool, Error> {
        let result: Vec<User> = get_any_from_key("username", username.as_bytes(), &mut self.db)?;
        Ok(!result.is_empty())
    }

    pub fn get_user_by_uuid(&mut self, uuid: &UuidModel) -> Result<User, Error> {
        let result = get_single_from_key("uuid", uuid.0.as_bytes(), &mut self.db)?;
        Ok(result)
    }

    pub fn get_chats_from_user(&mut self, user: &User) -> Result<Vec<Chat>, Error> {
        let chat_uuids = user.chats.clone();
        let mut chats = Vec::new();
        for chat_uuid in chat_uuids {
            let chat = get_single_from_key("uuid", chat_uuid.0.as_bytes(), &mut self.db)?;
            chats.push(chat);
        }
        Ok(chats)
    }
    pub fn get_messages_from_chat(&mut self, chat: &Chat) -> Result<Vec<Message>, Error> {
        let message_uuids = chat.messages.clone();
        let mut messages = Vec::new();
        for message_uuid in message_uuids {
            let message = get_single_from_key("uuid", message_uuid.0.as_bytes(), &mut self.db)?;
            messages.push(message);
        }
        Ok(messages)
    }

    pub fn add_image_to_message(
        &mut self,
        sender: &User,
        chat: &Chat,
        message: &Message,
        image: &Image,
    ) -> Result<(), Box<dyn std::error::Error>> {
        let image_path = match message.get_path_for_image(chat, sender) {
            Some(path) => path,
            None => return Err("No path found".into()),
        };

        //create directory recursively if it doesn't exist
        std::fs::create_dir_all(&image_path)?;

        save_as_webp(
            &image.b64_content,
            &image.image_type,
            Path::new(&image_path),
        )?;

        let new_message = Message {
            image: None,
            image_type: Some(image.image_type.clone()),
            ..message.clone()
        };

        self.insert_message(&new_message)?;
        Ok(())
    }

    pub fn get_images_from_message(
        &mut self,
        sender: &User,
        chat: &Chat,
        message: &Message,
    ) -> Result<Vec<Image>, Box<dyn std::error::Error>> {
        let user_image_path = "images/".to_owned() + &sender.uuid.0;
        let chat_id = chat.uuid.0.clone();
        let message_id = message.uuid.0.clone();
        let message_image_path = user_image_path.clone() + "/" + &chat_id + "/" + &message_id;
        let mut images = Vec::new();
        for entry in std::fs::read_dir(&message_image_path)? {
            let entry = entry?;
            let path = entry.path();
            let ext = path.extension().unwrap().to_str().unwrap();

            //read path to bytes and convert bytes to base64
            let mut file = std::fs::File::open(&path)?;
            let mut buffer = Vec::new();
            file.read_to_end(&mut buffer)?;
            #[allow(deprecated)]
            let b64_content = base64::encode(&buffer);

            let image = Image {
                image_type: ElodateImageFormat::from_ext(ext).unwrap(),
                b64_content: b64_content,
            };
            images.push(image);
        }
        Ok(images)
    }

    pub fn add_image_to_user(
        &mut self,
        user: &User,
        image: &Image,
    ) -> Result<UuidModel, Box<dyn std::error::Error>> {
        let user_image_path = "images/".to_owned() + &user.uuid.0;
        let image_id = UuidModel::new();
        let image_path =
            user_image_path.clone() + "/" + &image_id.0 + "." + image.image_type.to_ext();

        //create directory recursively if it doesn't exist
        std::fs::create_dir_all(&user_image_path)?;

        save_as_webp(
            &image.b64_content,
            &image.image_type,
            Path::new(&image_path),
        )?;

        Ok(image_id)
    }

    pub fn get_images_from_user(
        &mut self,
        user: &User,
    ) -> Result<Vec<Image>, Box<dyn std::error::Error>> {
        let user_image_path = "images/".to_owned() + &user.uuid.0;
        let mut images = Vec::new();
        for entry in std::fs::read_dir(&user_image_path)? {
            let entry = entry?;
            let path = entry.path();
            let ext = path.extension().unwrap().to_str().unwrap();

            //read path to bytes and convert bytes to base64
            let mut file = std::fs::File::open(&path)?;
            let mut buffer = Vec::new();
            file.read_to_end(&mut buffer)?;
            #[allow(deprecated)]
            let b64_content = base64::encode(&buffer);

            let image = Image {
                image_type: ElodateImageFormat::from_ext(ext).unwrap(),
                b64_content: b64_content,
            };
            images.push(image);
        }
        Ok(images)
    }

    pub fn get_mutual_preference_users(&mut self, user: &User) -> Result<Vec<User>, Error> {
        let min_age = user.public.preference.with_defaults().min_age.unwrap();
        let max_age = user.public.preference.with_defaults().max_age.unwrap();
        let min_gender_male = user
            .public
            .preference
            .with_defaults()
            .min_gender
            .unwrap()
            .percent_male;
        let min_gender_female = user
            .public
            .preference
            .with_defaults()
            .min_gender
            .unwrap()
            .percent_female;
        let max_gender_male = user
            .public
            .preference
            .with_defaults()
            .max_gender
            .unwrap()
            .percent_male;
        let max_gender_female = user
            .public
            .preference
            .with_defaults()
            .max_gender
            .unwrap()
            .percent_female;

        let min_date = chrono::Utc::now() - chrono::Duration::weeks(max_age as i64 * 52);
        let max_date = chrono::Utc::now() - chrono::Duration::weeks(min_age as i64 * 52);
        let min_timestamp = (min_date.timestamp() + 10000000000) as usize;
        let max_timestamp = (max_date.timestamp() + 10000000000) as usize;
        let users_age = get_documents_in_range(
            "birthdate",
            &min_timestamp.to_be_bytes(),
            &max_timestamp.to_be_bytes(),
            &mut self.db,
        )?;
        let users_female = get_documents_in_range(
            "gender.percent_female",
            &min_gender_female.to_be_bytes(),
            &max_gender_female.to_be_bytes(),
            &mut self.db,
        )?;

        let users_male = get_documents_in_range(
            "gender.percent_male",
            &min_gender_male.to_be_bytes(),
            &max_gender_male.to_be_bytes(),
            &mut self.db,
        )?;

        //intersect the sets
        let users = users_age
            .into_iter()
            .filter(|user| users_male.contains(user) && users_female.contains(user))
            .collect::<Vec<Box<[u8]>>>();

        let mut all_users = Vec::new();
        for user in users {
            let user: User = self
                .db
                .get(user)?
                .map(|user| Ok(user))
                .unwrap_or(Err(Error::Serde("No user found".to_owned())))?;

            all_users.push(user);
        }

        let users_who_prefer_me = all_users
            .iter()
            .filter(|user| {
                let min_age = user.public.preference.with_defaults().min_age.unwrap();
                let max_age = user.public.preference.with_defaults().max_age.unwrap();
                let min_gender_male = user
                    .public
                    .preference
                    .with_defaults()
                    .min_gender
                    .unwrap()
                    .percent_male;
                let min_gender_female = user
                    .public
                    .preference
                    .with_defaults()
                    .min_gender
                    .unwrap()
                    .percent_female;
                let max_gender_male = user
                    .public
                    .preference
                    .with_defaults()
                    .max_gender
                    .unwrap()
                    .percent_male;
                let max_gender_female = user
                    .public
                    .preference
                    .with_defaults()
                    .max_gender
                    .unwrap()
                    .percent_female;

                let min_date = chrono::Utc::now() - chrono::Duration::weeks(max_age as i64 * 52);
                let max_date = chrono::Utc::now() - chrono::Duration::weeks(min_age as i64 * 52);

                let my_age = user.public.birthdate;
                let my_gender_male = user.public.gender.percent_male;
                let my_gender_female = user.public.gender.percent_female;

                let perfered = min_date.timestamp() <= my_age
                    && my_age <= max_date.timestamp()
                    && min_gender_male <= my_gender_male
                    && my_gender_male <= max_gender_male
                    && min_gender_female <= my_gender_female
                    && my_gender_female <= max_gender_female;

                perfered
            })
            .map(|user| user.clone())
            .collect::<Vec<User>>();

        Ok(users_who_prefer_me)
    }
}

fn mapper(key: &[u8], value: &[u8], view: &str, emitter: &Emitter) -> Result<(), Error> {
    if &key[..5] == b"user/".as_ref() {
        let user = User::from_bytes(key, value)?;
        user.map(view, emitter)?;
        Ok(())
    } else if &key[..5] == b"chat/".as_ref() {
        let chat = Chat::from_bytes(key, value)?;
        chat.map(view, emitter)?;
        Ok(())
    } else if &key[..8] == b"message/".as_ref() {
        let message = Message::from_bytes(key, value)?;
        message.map(view, emitter)?;
        Ok(())
    } else if &key[..5] == b"flag/".as_ref() {
        Ok(())
    } else {
        let key_string = std::str::from_utf8(key).unwrap();
        let value_string = std::str::from_utf8(value).unwrap();
        Err(Error::Serde(format!(
            "Unknown key: {:?}\n value: {:?}\n view: {:?}",
            key_string, value_string, view
        )))
    }
}

const VIEWS: [&str; 14] = [
    //ids
    "uuid",
    //access codes
    "code",
    //chats
    "user1",
    "user2",
    //users
    "username",
    "preference.min_age",
    "preference.max_age",
    "preference.max_gender.percent_male",
    "preference.max_gender.percent_female",
    "preference.min_gender.percent_male",
    "preference.min_gender.percent_female",
    "birthdate",
    "gender.percent_male",
    "gender.percent_female",
];

impl Document for User {
    fn from_bytes(_key: &[u8], value: &[u8]) -> Result<Self, Error> {
        let serde_result: User =
            serde_cbor::from_slice(value).map_err(|err| Error::Serde(format!("{}", err)))?;
        Ok(serde_result)
    }

    fn to_bytes(&self) -> Result<Vec<u8>, Error> {
        let encoded: Vec<u8> =
            serde_cbor::to_vec(self).map_err(|err| Error::Serde(format!("{}", err)))?;
        Ok(encoded)
    }

    fn map(&self, view: &str, emitter: &Emitter) -> Result<(), Error> {
        match view {
            "uuid" => {
                let bytes = self.uuid.0.as_bytes();
                emitter.emit(bytes, None)?;
            }
            "username" => {
                let bytes = self.public.username.as_bytes();

                emitter.emit(bytes, None)?;
            }
            "preference.min_age" => {
                let bytes = self
                    .public
                    .preference
                    .with_defaults()
                    .min_age
                    .unwrap()
                    .to_be_bytes();

                emitter.emit(&base32::encode(&bytes), None)?;
            }
            "preference.max_age" => {
                let bytes = self
                    .public
                    .preference
                    .with_defaults()
                    .max_age
                    .unwrap()
                    .to_be_bytes();

                emitter.emit(&base32::encode(&bytes), None)?;
            }
            "preference.max_gender.percent_male" => {
                let bytes = self
                    .public
                    .preference
                    .with_defaults()
                    .max_gender
                    .unwrap()
                    .percent_male
                    .to_be_bytes();

                emitter.emit(&base32::encode(&bytes), None)?;
            }
            "preference.max_gender.percent_female" => {
                let bytes = self
                    .public
                    .preference
                    .with_defaults()
                    .max_gender
                    .unwrap()
                    .percent_female
                    .to_be_bytes();

                emitter.emit(&base32::encode(&bytes), None)?;
            }
            "preference.min_gender.percent_male" => {
                let bytes = self
                    .public
                    .preference
                    .with_defaults()
                    .min_gender
                    .unwrap()
                    .percent_male
                    .to_be_bytes();

                emitter.emit(&base32::encode(&bytes), None)?;
            }
            "preference.min_gender.percent_female" => {
                let bytes = self
                    .public
                    .preference
                    .with_defaults()
                    .min_gender
                    .unwrap()
                    .percent_female
                    .to_be_bytes();

                emitter.emit(&base32::encode(&bytes), None)?;
            }
            "birthdate" => {
                let bytes = ((self.public.birthdate + 10000000000) as usize).to_be_bytes();

                emitter.emit(&base32::encode(&bytes), None)?;
            }
            "gender.percent_male" => {
                let bytes = self.public.gender.percent_male.to_be_bytes();

                emitter.emit(&base32::encode(&bytes), None)?;
            }
            "gender.percent_female" => {
                let bytes = self.public.gender.percent_female.to_be_bytes();

                emitter.emit(&base32::encode(&bytes), None)?;
            }
            _ => {}
        }
        Ok(())
    }
}

impl Document for Message {
    fn from_bytes(_key: &[u8], value: &[u8]) -> Result<Self, Error> {
        let serde_result: Message =
            serde_cbor::from_slice(value).map_err(|err| Error::Serde(format!("{}", err)))?;
        Ok(serde_result)
    }

    fn to_bytes(&self) -> Result<Vec<u8>, Error> {
        let encoded = serde_cbor::to_vec(self).map_err(|err| Error::Serde(format!("{}", err)))?;
        Ok(encoded)
    }

    fn map(&self, view: &str, emitter: &Emitter) -> Result<(), Error> {
        match view {
            "uuid" => {
                let bytes = self.uuid.0.as_bytes();
                emitter.emit(bytes, None)?;
            }
            _ => {}
        };

        Ok(())
    }
}

impl Document for Chat {
    fn from_bytes(_key: &[u8], value: &[u8]) -> Result<Self, Error> {
        let serde_result: Chat =
            serde_cbor::from_slice(value).map_err(|err| Error::Serde(format!("{}", err)))?;
        Ok(serde_result)
    }

    fn to_bytes(&self) -> Result<Vec<u8>, Error> {
        let encoded = serde_cbor::to_vec(self).map_err(|err| Error::Serde(format!("{}", err)))?;
        Ok(encoded)
    }

    fn map(&self, view: &str, emitter: &Emitter) -> Result<(), Error> {
        match view {
            "uuid" => {
                let bytes = self.uuid.0.as_bytes();
                emitter.emit(bytes, None)?;
            }
            "user1" => {
                let bytes = self.user1.0.as_bytes();

                emitter.emit(bytes, None)?;
            }
            "user2" => {
                let bytes = self.user2.0.as_bytes();

                emitter.emit(bytes, None)?;
            }
            _ => {}
        };
        Ok(())
    }
}

impl Document for AccessCode {
    fn from_bytes(_key: &[u8], value: &[u8]) -> Result<Self, Error> {
        let serde_result: AccessCode =
            serde_cbor::from_slice(value).map_err(|err| Error::Serde(format!("{}", err)))?;
        Ok(serde_result)
    }

    fn to_bytes(&self) -> Result<Vec<u8>, Error> {
        let encoded = serde_cbor::to_vec(self).map_err(|err| Error::Serde(format!("{}", err)))?;
        Ok(encoded)
    }

    fn map(&self, view: &str, emitter: &Emitter) -> Result<(), Error> {
        match view {
            "uuid" => {
                let bytes = self.uuid.0.as_bytes();
                emitter.emit(bytes, None)?;
            }
            "code" => {
                let bytes = self.code.as_bytes();

                emitter.emit(bytes, None)?;
            }
            _ => {}
        };
        Ok(())
    }
}
