use std::error::Error;

use paperclip::actix::Apiv2Schema;
use serde::{Deserialize, Serialize};

use crate::models::internal_models::{
    internal_chat::InternalChat, internal_message::InternalMessage, internal_user::InternalUser,
};

use super::shared::ApiUuid;

#[derive(Debug, Serialize, Deserialize, Apiv2Schema)]
pub struct ApiChat {
    pub uuid: ApiUuid<InternalChat>,
    pub users: Vec<ApiUuid<InternalUser>>,
    pub unread: u32, //same order as users
    pub messages: Vec<ApiUuid<InternalMessage>>,
    pub most_recent_message: String,
    pub most_recent_sender: Option<ApiUuid<InternalUser>>,
    pub most_recent_message_sent_at: i64,
}

impl ApiChat {
    pub fn from_internal(chat: InternalChat, user: &InternalUser) -> Result<Self, Box<dyn Error>> {
        let user_index = chat
            .users
            .iter()
            .position(|u| u == &user.uuid)
            .ok_or("User not found")?;

        Ok(ApiChat {
            uuid: chat.uuid.into(),
            users: chat.users.into_iter().map(|u| u.into()).collect(),
            unread: chat.unread[user_index],
            messages: chat.messages.into_iter().map(|m| m.into()).collect(),
            most_recent_message: chat.most_recent_message.clone(),
            most_recent_sender: chat.most_recent_sender.map(|s| s.into()),
            most_recent_message_sent_at: chat.most_recent_message_sent_at,
        })
    }
}
