use async_mutex::Mutex;

use actix_web::{Error, HttpMessage, HttpRequest};

use paperclip::actix::{
    api_v2_operation, post,
    web::{self, Json},
    Apiv2Schema,
};
use serde::{Deserialize, Serialize};

use crate::{
    db::DB,
    models::{message::PublicMessage, shared::UuidModel},
    procedures::send_chat_message::send_chat_message,
};

#[derive(Debug, Clone, Serialize, Deserialize, Apiv2Schema)]
struct SendMessageInput {
    chat_uuid: UuidModel,
    message: PublicMessage,
}

#[api_v2_operation]
#[post("/send_message")]
pub async fn send_message(
    db: web::Data<Mutex<DB>>,
    req: HttpRequest,
    body: Json<SendMessageInput>,
) -> Result<Json<String>, Error> {
    let ext = req.extensions();
    let user_uuid = ext.get::<UuidModel>().unwrap();
    let mut db = db.lock().await;
    let inner = body.into_inner();
    let chat_uuid = inner.chat_uuid;
    let message = inner.message;

    let user = db.get_user_by_uuid(&user_uuid).map_err(|e| {
        println!("Failed to get user by uuid {:?}", e);
        actix_web::error::ErrorInternalServerError("Failed to get user by uuid")
    })?;

    let chat = db.get_chat(&chat_uuid).map_err(|e| {
        println!("Failed to get chat {:?}", e);
        actix_web::error::ErrorInternalServerError("Failed to get chat")
    })?;

    if &chat.user1 != user_uuid && &chat.user2 != user_uuid {
        println!("User not in chat");
        return Err(actix_web::error::ErrorBadRequest("Chat not found"));
    }

    send_chat_message(chat_uuid, user, message.to_message(user_uuid), &mut db)?;

    Ok(Json("success".to_string()))
}
