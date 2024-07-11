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
        api_models::shared::ApiUuid,
        internal_models::{
            internal_chat::InternalChat, internal_message::InternalMessage, shared::InternalUuid,
        },
    },
    routes::shared::route_body_mut_db,
};

#[derive(Debug, Deserialize, Apiv2Schema)]
struct DeleteMessageInput {
    chat_uuid: ApiUuid<InternalChat>,
    message_uuid: ApiUuid<InternalMessage>,
}

#[api_v2_operation]
#[post("/delete_message")]
pub fn delete_message(
    db: web::Data<DB>,
    req: HttpRequest,
    body: Json<DeleteMessageInput>,
) -> Result<Json<bool>, Error> {
    route_body_mut_db(db, req, body, |db, user, body| {
        let chat_uuid = body.chat_uuid;
        let message_uuid = body.message_uuid;

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

        //remove message from chat
        let internal_message_uuid: InternalUuid<InternalMessage> = message_uuid.into();
        chat.messages.retain(|m| m != &internal_message_uuid);

        //delete message
        internal_message_uuid.delete(db).map_err(|e| {
            log::error!("Failed to delete message {:?}", e);
            actix_web::error::ErrorInternalServerError("Failed to delete message")
        })?;

        Ok(true)
    })
}
