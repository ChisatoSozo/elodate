use actix_web::{Error, HttpRequest};

use paperclip::actix::{
    api_v2_operation, post,
    web::{self, Json},
    Apiv2Schema,
};
use serde::Deserialize;

use crate::{
    db::DB,
    models::{
        api_models::{api_message::ApiMessageWritable, shared::ApiUuid},
        internal_models::{
            internal_chat::InternalChat,
            internal_user::TimestampedAction,
            shared::{InternalUuid, Save},
        },
    },
    routes::shared::route_body_mut_db,
};

#[derive(Debug, Deserialize, Apiv2Schema)]
struct SendMessageInput {
    chat_uuid: ApiUuid<InternalChat>,
    message: ApiMessageWritable,
}

#[api_v2_operation]
#[post("/send_message")]
pub fn send_message(
    db: web::Data<DB>,
    req: HttpRequest,
    body: Json<SendMessageInput>,
) -> Result<Json<bool>, Error> {
    route_body_mut_db(db, req, body, |db, user, body| {
        let chat_uuid = body.chat_uuid;
        let message = body.message;

        let internal_chat_uuid: InternalUuid<InternalChat> = chat_uuid.into();

        let chat = internal_chat_uuid.load(db).map_err(|e| {
            log::error!("Failed to get chat {:?}", e);
            actix_web::error::ErrorInternalServerError("Failed to get chat")
        })?;

        let mut chat = match chat {
            Some(chat) => chat,
            None => return Err(actix_web::error::ErrorNotFound("Chat not found")),
        };

        //is user in chat
        if chat.users.iter().find(|u| u == &&user.uuid).is_none() {
            return Err(actix_web::error::ErrorBadRequest("User not in chat"));
        }

        let internal_message = message.into_internal(&user.uuid, &chat, db)?;

        internal_message.save(&mut chat, db).map_err(|e| {
            log::error!("Failed to save message {:?}", e);
            actix_web::error::ErrorInternalServerError("Failed to save message")
        })?;

        let mut user = user;
        user.actions.push(TimestampedAction {
            timestamp: chrono::Utc::now().timestamp(),
            action: crate::models::internal_models::internal_user::Action::SendMessage,
        });
        user.save(db)?;

        Ok(true)
    })
}
