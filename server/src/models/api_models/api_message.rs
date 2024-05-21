use paperclip::actix::Apiv2Schema;
use serde::{Deserialize, Serialize};

use crate::{
    db::DB,
    models::internal_models::{
        internal_chat::InternalChat,
        internal_image::{Access, InternalImage},
        internal_message::InternalMessage,
        internal_user::InternalUser,
        shared::{InternalUuid, Save},
    },
};

use super::{api_image::ApiImage, shared::ApiUuid};

#[derive(Debug, Clone, Serialize, Deserialize, Apiv2Schema)]
pub struct ApiMessage {
    pub uuid: ApiUuid<InternalMessage>,
    pub sent_at: i64,
    pub author: ApiUuid<InternalUser>,
    pub content: String,
    pub image: Option<ApiUuid<InternalImage>>,
    pub read_by: Vec<ApiUuid<InternalUser>>,
}

impl From<InternalMessage> for ApiMessage {
    fn from(message: InternalMessage) -> Self {
        Self {
            uuid: message.uuid.into(),
            sent_at: message.sent_at,
            author: message.author.into(),
            content: message.content,
            image: message.image.map(|i| i.into()),
            read_by: message.read_by.into_iter().map(|u| u.into()).collect(),
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize, Apiv2Schema)]
pub struct ApiMessageWritable {
    pub uuid: ApiUuid<InternalMessage>,
    pub sent_at: i64,
    pub content: String,
    pub image: Option<ApiImage>,
}

impl ApiMessageWritable {
    pub fn into_internal(
        self,
        user: InternalUser,
        chat: &InternalChat,
        db: &DB,
    ) -> Result<InternalMessage, actix_web::Error> {
        //does it exist?
        let internal_uuid: InternalUuid<InternalMessage> = self.uuid.into();
        let message = internal_uuid.load(db).map_err(|e| {
            println!("Failed to get message {:?}", e);
            actix_web::error::ErrorInternalServerError("Failed to get message")
        })?;

        //if it already exists, are you the author
        let mut message = match message {
            Some(message) => {
                if message.author != user.uuid {
                    return Err(actix_web::error::ErrorBadRequest("Not the author"));
                }
                //is the message in the chat?
                if !chat.messages.contains(&message.uuid) {
                    return Err(actix_web::error::ErrorBadRequest("Message not in chat"));
                }
                let mut message = message;
                message.sent_at = self.sent_at;
                message.content = self.content;
                message
            }
            None => InternalMessage {
                uuid: InternalUuid::new(),
                sent_at: self.sent_at,
                author: user.uuid.clone(),
                content: self.content,
                image: None,
                read_by: vec![user.uuid],
            },
        };
        let internal_image = self
            .image
            .map(|i| i.to_internal(Access::UserList(chat.users.clone())));
        if let Some(internal_image) = internal_image {
            let image_uuid = internal_image.save(db)?;
            message.image = Some(image_uuid);
        }
        Ok(message)
    }
}
