use actix_web::Error;

use paperclip::actix::{
    api_v2_operation, post,
    web::{self, Json},
};

use crate::{
    db::DB,
    models::{
        api_models::{api_message::ApiMessage, shared::ApiUuid},
        internal_models::{
            internal_chat::InternalChat, internal_message::InternalMessage, shared::InternalUuid,
        },
    },
    routes::shared::route_body_mut_db,
};

#[api_v2_operation]
#[post("/get_message")]
pub fn get_message(
    db: web::Data<DB>,
    req: web::HttpRequest,
    body: Json<ApiUuid<InternalMessage>>,
) -> Result<Json<ApiMessage>, Error> {
    route_body_mut_db(db, req, body, |db, user, body| {
        let message_uuid: InternalUuid<InternalMessage> = body.into();
        let message = message_uuid.load(db).map_err(|e| {
            log::error!("Failed to get message {:?}", e);
            actix_web::error::ErrorInternalServerError("Failed to get message")
        })?;

        let message = match message {
            Some(message) => message,
            None => return Err(actix_web::error::ErrorNotFound("Message not found")),
        };

        let chat_uuid = message.chat.clone();

        //is this user in this chat?
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

        Ok(message.into())
    })
}
