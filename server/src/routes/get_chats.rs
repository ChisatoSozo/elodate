use actix_web::Error;

use paperclip::actix::{
    api_v2_operation, post,
    web::{self, Json},
};

use crate::{
    db::DB,
    models::{
        api_models::{api_chat::ApiChat, shared::ApiUuid},
        internal_models::{internal_chat::InternalChat, shared::InternalUuid},
    },
    routes::shared::route_body_mut_db,
};

#[api_v2_operation]
#[post("/get_chats")]
pub fn get_chats(
    db: web::Data<DB>,
    req: web::HttpRequest,
    body: Json<Vec<ApiUuid<InternalChat>>>,
) -> Result<Json<Vec<ApiChat>>, Error> {
    route_body_mut_db(db, req, body, |db, user, body| {
        //is this user in this chat?

        let chats = body
            .into_iter()
            .map(|chat_uuid| {
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

                Ok(chat)
            })
            .collect::<Result<Vec<_>, _>>()?;

        let api_chats: Vec<ApiChat> = chats
            .into_iter()
            .map(|chat| ApiChat::from_internal(chat, &user))
            .collect::<Result<Vec<_>, _>>()?;
        Ok(api_chats)
    })
}
