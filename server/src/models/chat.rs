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

impl Chat {
    pub fn get_messages(&self, db: &mut DB) -> Result<Vec<Message>, Box<dyn Error>> {
        let mut messages = vec![];
        for message_uuid in self.messages.iter() {
            let chat = db.get_message(message_uuid)?;
            messages.push(chat);
        }

        Ok(messages)
    }
}
