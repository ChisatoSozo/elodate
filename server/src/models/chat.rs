use std::error::Error;

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
