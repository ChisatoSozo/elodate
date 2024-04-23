use paperclip::actix::Apiv2Schema;
use serde::{Deserialize, Serialize};

// A trait that the Validate derive will impl
use validator::Validate;

use super::{message::Message, shared::UuidModel};

#[derive(Debug, Validate, Serialize, Deserialize, Apiv2Schema, Clone)]
pub struct Chat {
    pub uuid: UuidModel,
    pub user1: UuidModel,
    pub user2: UuidModel,
    pub messages: Vec<UuidModel>,
    //validate max length of 3
    #[validate(length(max = 3, message = "Only 3 images allowed per user per chat"))]
    pub user1_image_ids: Vec<UuidModel>,
    #[validate(length(max = 3, message = "Only 3 images allowed per user per chat"))]
    pub user2_image_ids: Vec<UuidModel>,
}

impl Chat {
    pub fn random_chat(user1: UuidModel, user2: UuidModel) -> (Chat, Vec<Message>) {
        let mut messages = vec![];
        let mut message_entities = vec![];

        for i in 0..10 {
            let message = Message::random_message(if i % 2 == 0 {
                user1.clone()
            } else {
                user2.clone()
            });
            messages.push(message.uuid.clone());
            message_entities.push(message);
        }

        let chat = Chat {
            uuid: UuidModel::new(),
            user1,
            user2,
            messages,
            user1_image_ids: Vec::new(),
            user2_image_ids: Vec::new(),
        };

        (chat, message_entities)
    }
}
