use paperclip::actix::Apiv2Schema;
use serde::{Deserialize, Serialize};

use crate::{
    db::DB,
    models::internal_models::{
        internal_chat::InternalChat, internal_image::InternalImage,
        internal_message::InternalMessage, internal_user::InternalUser, shared::InternalUuid,
    },
};

use super::shared::ApiUuid;

#[derive(Debug, Clone, Serialize, Apiv2Schema)]
pub struct ApiMessage {
    pub uuid: ApiUuid<InternalMessage>,
    pub sent_at: i64,
    pub author: ApiUuid<InternalUser>,
    pub content: String,
    pub image: Option<ApiUuid<InternalImage>>,
    pub read_by: Vec<ApiUuid<InternalUser>>,
    pub edited: bool,
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
            edited: message.edited,
        }
    }
}

#[derive(Debug, Clone, Deserialize, Apiv2Schema)]
pub struct ApiMessageWritable {
    pub uuid: Option<ApiUuid<InternalMessage>>,
    pub content: String,
    pub image: Option<ApiUuid<InternalImage>>,
}

impl ApiMessageWritable {
    pub fn into_internal(
        self,
        user: &InternalUser,
        chat: &InternalChat,
        db: &DB,
    ) -> Result<InternalMessage, actix_web::Error> {
        //does it exist?

        //if it already exists, are you the author
        let mut message = match self.uuid {
            Some(message) => {
                let internal_uuid: InternalUuid<InternalMessage> = message.into();
                let message = internal_uuid.load(db).map_err(|e| {
                    println!("Failed to get message {:?}", e);
                    actix_web::error::ErrorInternalServerError("Failed to get message")
                })?;
                let message = match message {
                    Some(message) => message,
                    None => {
                        return Err(actix_web::error::ErrorBadRequest("Message does not exist"));
                    }
                };
                if message.author != user.uuid {
                    return Err(actix_web::error::ErrorBadRequest("Not the author"));
                }
                //is the message in the chat?
                if !chat.messages.contains(&message.uuid) {
                    return Err(actix_web::error::ErrorBadRequest("Message not in chat"));
                }
                let mut message = message;
                message.sent_at = chrono::Utc::now().timestamp();
                message.content = self.content;
                message.edited = true;
                message
            }
            None => InternalMessage {
                uuid: InternalUuid::new(),
                sent_at: chrono::Utc::now().timestamp(),
                author: user.uuid.clone(),
                content: self.content,
                edited: false,
                image: None,
                read_by: vec![user.uuid.clone()],
                chat: chat.uuid.clone(),
            },
        };

        //is there an image
        match self.image {
            Some(image) => {
                //does image exist
                let internal_uuid: InternalUuid<InternalImage> = image.into();
                let archived = internal_uuid.load(db).map_err(|e| {
                    println!("Failed to get image {:?}", e);
                    actix_web::error::ErrorInternalServerError("Failed to get image")
                })?;
                match archived {
                    Some(image) => {
                        //permissions?
                        if !image.access.can_access(&user.uuid) {
                            return Err(actix_web::error::ErrorBadRequest("No access to image"));
                        }
                        message.image = Some(image.uuid);
                    }
                    None => {
                        return Err(actix_web::error::ErrorBadRequest(
                            "Image does not exist, api_message",
                        ));
                    }
                }
            }
            None => (),
        }

        Ok(message)
    }
}
