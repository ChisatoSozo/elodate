use std::path::Path;
//TODO: encryption at rest
use crate::{
    db::get_single_from_key,
    mokuroku::lib::{Document, Emitter, Error as MkrkError},
    util::save_as_webp,
};
use paperclip::actix::Apiv2Schema;
use serde::{Deserialize, Serialize};

// A trait that the Validate derive will impl
use validator::Validate;

use crate::db::DB;

use super::{
    chat::Chat,
    image::{ElodateImageFormat, Image},
    shared::UuidModel,
    user::User,
};

#[derive(Debug, Validate, Serialize, Deserialize, Apiv2Schema, Clone)]
pub struct Message {
    pub uuid: UuidModel,
    pub sent_at: i64,
    pub author: UuidModel,
    #[validate(length(min = 1, message = "Message content must not be empty"))]
    pub content: String,
    pub image: Option<Image>,
    pub image_type: Option<ElodateImageFormat>,
    pub reciever_read: bool,
}

#[derive(Debug, Validate, Serialize, Deserialize, Apiv2Schema, Clone)]
pub struct PublicMessage {
    pub content: String,
    pub image: Option<Image>,
    pub image_type: Option<ElodateImageFormat>,
}

impl PublicMessage {
    pub fn to_message(&self, author: &UuidModel) -> Message {
        Message {
            uuid: UuidModel::new(),
            sent_at: chrono::Utc::now().timestamp_millis() / 1000,
            author: author.clone(),
            content: self.content.clone(),
            image: self.image.clone(),
            image_type: self.image_type.clone(),
            reciever_read: false,
        }
    }
}

impl Message {
    pub fn get_path_for_image(
        &self,
        chat: &Chat,
        sender: &User,
        image_type: &ElodateImageFormat,
        db: &DB,
    ) -> String {
        let user_image_path = db.path.clone() + "/images/" + &sender.uuid.0;
        let chat_id = chat.uuid.0.clone();
        let message_id = self.uuid.0.clone();
        let image_path = user_image_path.clone()
            + "/"
            + &chat_id
            + "/"
            + &message_id
            + "."
            + image_type.to_ext();

        image_path
    }

    pub fn fill_image(
        &mut self,
        chat: &Chat,
        user: &User,
        db: &DB,
    ) -> Result<(), Box<dyn std::error::Error>> {
        let image_type = match &self.image_type {
            Some(image_type) => image_type,
            None => return Ok(()),
        };
        let path = self.get_path_for_image(chat, user, image_type, db);

        let exists = std::path::Path::new(&path).exists();
        if !exists {
            self.image = None;
            self.image_type = None;
            return Ok(());
        }

        let image = Image::load(&path)?;

        self.image = Some(image);
        Ok(())
    }

    pub fn save_message(
        &self,
        chat: &Chat,
        user: &User,
        db: &mut DB,
    ) -> Result<(), Box<dyn std::error::Error>> {
        if self.image.is_some() {
            db.add_image_to_message_and_insert(user, chat, self)?;
        } else {
            db.insert_message(self)?;
        }

        Ok(())
    }
}

impl Document for Message {
    fn from_bytes(_key: &[u8], value: &[u8]) -> Result<Self, MkrkError> {
        let serde_result: Message =
            serde_cbor::from_slice(value).map_err(|err| MkrkError::Serde(format!("{}", err)))?;
        Ok(serde_result)
    }

    fn to_bytes(&self) -> Result<Vec<u8>, MkrkError> {
        let encoded =
            serde_cbor::to_vec(self).map_err(|err| MkrkError::Serde(format!("{}", err)))?;
        Ok(encoded)
    }

    fn map(&self, view: &str, emitter: &Emitter) -> Result<(), MkrkError> {
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

impl DB {
    pub fn insert_message(&mut self, message: &Message) -> Result<(), MkrkError> {
        let key = &message.uuid.0;
        let key = "message/".to_string() + key;
        self.db.put(key, message)?;
        Ok(())
    }

    pub fn get_message(&mut self, message_uuid: &UuidModel) -> Result<Message, MkrkError> {
        let result = get_single_from_key("uuid", message_uuid.0.as_bytes(), &mut self.db)?;
        Ok(result)
    }

    pub fn add_image_to_message_and_insert(
        &mut self,
        sender: &User,
        chat: &Chat,
        message: &Message,
    ) -> Result<(), Box<dyn std::error::Error>> {
        let image = match &message.image {
            Some(image) => image,
            None => {
                return Err("Message does not have an image".into());
            }
        };
        let image_path = message.get_path_for_image(chat, sender, &image.image_type, &self);

        let parent_dir = Path::new(&image_path).parent().unwrap();
        std::fs::create_dir_all(&parent_dir)?;
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
}
