use std::error::Error;

use crate::{
    db::get_single_from_key,
    mokuroku::lib::{Document, Emitter, Error as MkrkError},
};
use paperclip::actix::Apiv2Schema;
use serde::{Deserialize, Serialize};
// A trait that the Validate derive will impl
use validator::Validate;

use crate::db::DB;

use super::{message::Message, shared::UuidModel};

#[derive(Debug, Validate, Serialize, Deserialize, Apiv2Schema, Clone)]
pub struct Chat {
    pub uuid: UuidModel,
    pub user1: UuidModel,
    pub user2: UuidModel,
    pub messages: Vec<UuidModel>,
}

#[derive(Debug, Validate, Serialize, Deserialize, Apiv2Schema, Clone)]
pub struct ChatAndLastMessage {
    pub chat: Chat,
    pub last_message: Message,
}

impl Chat {
    pub fn get_messages(&self, db: &mut DB) -> Result<Vec<Message>, Box<dyn Error>> {
        let mut messages = vec![];
        for message_uuid in self.messages.iter() {
            let chat = db.get_message(message_uuid)?;
            messages.push(chat);
        }

        Ok(messages)
    }

    pub fn get_last_message(&self, db: &mut DB) -> Result<Message, Box<dyn Error>> {
        let last_message_uuid = match self.messages.last() {
            Some(uuid) => uuid,
            None => return Err("No messages in chat".into()),
        };
        let last_message = db.get_message(last_message_uuid)?;

        Ok(last_message)
    }
}

impl Document for Chat {
    fn from_bytes(_key: &[u8], value: &[u8]) -> Result<Self, MkrkError> {
        let serde_result: Chat =
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

impl DB {
    pub fn insert_chat(&mut self, chat: &Chat) -> Result<(), MkrkError> {
        let key = &chat.uuid.0;
        let key = "chat/".to_string() + key;
        self.db.put(key, chat)?;
        Ok(())
    }

    pub fn get_chat(&mut self, chat_uuid: &UuidModel) -> Result<Chat, MkrkError> {
        let result = get_single_from_key("uuid", chat_uuid.0.as_bytes(), &mut self.db)?;
        Ok(result)
    }
}
