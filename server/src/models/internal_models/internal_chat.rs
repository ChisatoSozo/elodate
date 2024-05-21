use std::error::Error;

use crate::db::DB;

use super::shared::{InternalUuid, Save};
use super::{internal_message::InternalMessage, internal_user::InternalUser};

#[derive(Debug, Clone, rkyv::Archive, rkyv::Serialize, rkyv::Deserialize)]
#[archive(compare(PartialEq), check_bytes)]
pub struct InternalChat {
    pub uuid: InternalUuid<InternalChat>,
    pub users: Vec<InternalUuid<InternalUser>>,
    pub unread: Vec<u32>, //same order as users
    pub messages: Vec<InternalUuid<InternalMessage>>,
    pub most_recent_message: String,
}

impl InternalChat {
    pub fn new(users: Vec<InternalUuid<InternalUser>>) -> InternalChat {
        let users_len = users.len();
        InternalChat {
            uuid: InternalUuid::<InternalChat>::new(),
            users,
            unread: vec![0; users_len],
            messages: vec![],
            most_recent_message: "No messages yet".to_string(),
        }
    }

    pub fn get_messages(&self, db: &mut DB) -> Result<Vec<InternalMessage>, Box<dyn Error>> {
        let mut messages = vec![];
        for message_uuid in self.messages.iter() {
            let message = message_uuid.load(db)?;
            let message = match message {
                Some(message) => message,
                None => return Err("Message not found".into()),
            };
            messages.push(message);
        }

        Ok(messages)
    }

    pub fn get_last_message(&self, db: &mut DB) -> Result<InternalMessage, Box<dyn Error>> {
        let last_message_uuid = match self.messages.last() {
            Some(uuid) => uuid,
            None => return Err("No messages in chat".into()),
        };
        let last_message = last_message_uuid.load(db)?;
        let last_message = match last_message {
            Some(message) => message,
            None => return Err("Message not found".into()),
        };

        Ok(last_message)
    }

    pub fn add_message(
        &mut self,
        message: InternalMessage,
        user: &InternalUser,
        db: &mut DB,
    ) -> Result<(), Box<dyn Error>> {
        self.messages.push(message.uuid.clone());
        self.most_recent_message = if message.content.is_empty() {
            if message.image.is_some() {
                "Image".to_string()
            } else {
                return Err("Message content is empty".into());
            }
        } else {
            message.content.clone()
        };
        // get user index
        let user_index = self
            .users
            .iter()
            .position(|u| u == &user.uuid)
            .ok_or("User not found in chat")?;
        // increment unread count for all other users
        for (i, unread) in self.unread.iter_mut().enumerate() {
            if i != user_index {
                *unread += 1;
            }
        }
        message.save(db)?;
        Ok(())
    }
}

impl Save for InternalChat {
    fn save(self, db: &mut DB) -> Result<(), Box<dyn Error>> {
        db.write_object(&self.uuid, &self)?;
        Ok(())
    }
}
