use actix_web::Error;

use paperclip::actix::{
    api_v2_operation, post,
    web::{self, Json},
    Apiv2Schema,
};
use serde::{Deserialize, Serialize};

use crate::{
    db::DB,
    models::{
        api_models::{api_message::ApiMessage, shared::ApiUuid},
        internal_models::{
            internal_chat::InternalChat,
            internal_message::InternalMessage,
            internal_user::Notification,
            shared::{InternalUuid, Save},
        },
    },
    routes::shared::route_body_mut_db,
};

#[derive(Debug, Serialize, Deserialize, Apiv2Schema)]
struct GetMessagesInput {
    chat_uuid: ApiUuid<InternalChat>,
    messages: Vec<ApiUuid<InternalMessage>>,
}

#[api_v2_operation]
#[post("/get_messages")]
pub fn get_messages(
    db: web::Data<DB>,
    req: web::HttpRequest,
    body: Json<GetMessagesInput>,
) -> Result<Json<Vec<ApiMessage>>, Error> {
    route_body_mut_db(db, req, body, |db, user, body| {
        //is this user in this chat?
        let chat_uuid = body.chat_uuid;
        let internal_chat_uuid: InternalUuid<InternalChat> = chat_uuid.into();
        let chat = internal_chat_uuid.load(db).map_err(|e| {
            log::error!("Failed to get chat {:?}", e);
            actix_web::error::ErrorInternalServerError("Failed to get chat")
        })?;

        let chat = match chat {
            Some(chat) => chat,
            None => return Err(actix_web::error::ErrorNotFound("Chat not found")),
        };

        let user_uuid = &user.uuid;
        if chat.users.iter().find(|u| u == &user_uuid).is_none() {
            return Err(actix_web::error::ErrorBadRequest("User not in chat"));
        }

        let messages = body
            .messages
            .into_iter()
            .map(|message_uuid| {
                let internal_uuid: InternalUuid<_> = message_uuid.into();
                internal_uuid
                    .load(db)
                    .map_err(|e| {
                        log::error!("Failed to get message by uuid {:?}", e);
                        actix_web::error::ErrorInternalServerError("Failed to get message by uuid")
                    })
                    .and_then(|message| {
                        message.ok_or_else(|| actix_web::error::ErrorNotFound("User not found"))
                    })
            })
            .collect::<Result<Vec<_>, _>>()?;

        //set unread for this user to 0
        let user_idx = chat
            .users
            .iter()
            .position(|u| u == user_uuid)
            .ok_or_else(|| actix_web::error::ErrorInternalServerError("User not in chat"))?;

        let mut chat = chat;
        chat.unread[user_idx] = 0;
        chat.save(db)?;

        let mut user = user;
        //clear message from unread
        user.notifications.retain(|n| {
            if let Notification::UnreadMessage(message_uuid) = n {
                if messages.iter().any(|m| m.uuid == *message_uuid) {
                    return false;
                }
            }
            true
        });
        user.save(db)?;

        let api_messages: Vec<ApiMessage> = messages
            .into_iter()
            .map(ApiMessage::from)
            .collect::<Vec<_>>();

        Ok(api_messages)
    })
}
