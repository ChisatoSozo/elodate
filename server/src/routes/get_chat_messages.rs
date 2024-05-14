use async_mutex::Mutex;

use actix_web::{Error, HttpMessage, HttpRequest};

use paperclip::actix::{
    api_v2_operation, post,
    web::{self, Json},
};

use crate::{
    db::DB,
    models::{message::Message, shared::UuidModel},
};

#[api_v2_operation]
#[post("/get_chat_messages")]
pub async fn get_chat_messages(
    db: web::Data<Mutex<DB>>,
    req: HttpRequest,
    body: Json<UuidModel>,
) -> Result<Json<Vec<Message>>, Error> {
    let chat_uuid = body.into_inner();
    let ext = req.extensions();
    let user_uuid = ext.get::<UuidModel>().unwrap();
    let mut db = db.lock().await;
    let user = db.get_user_by_uuid(&user_uuid).map_err(|e| {
        println!("Failed to get user by uuid {:?}", e);
        actix_web::error::ErrorInternalServerError("Failed to get user by uuid")
    })?;

    if user.chats.iter().find(|chat| chat == &&chat_uuid).is_none() {
        return Err(actix_web::error::ErrorBadRequest("Chat not found"));
    }

    let chat = db.get_chat(&chat_uuid).map_err(|e| {
        println!("Failed to get chat {:?}", e);
        actix_web::error::ErrorInternalServerError("Failed to get chat")
    })?;

    let messages = chat.get_messages(&mut db).map_err(|e| {
        println!("Failed to get messages {:?}", e);
        actix_web::error::ErrorInternalServerError("Failed to get messages")
    })?;

    Ok(Json(messages))
}
