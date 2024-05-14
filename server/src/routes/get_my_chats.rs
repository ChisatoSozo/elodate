use async_mutex::Mutex;

use actix_web::{Error, HttpMessage, HttpRequest};

use paperclip::actix::{
    api_v2_operation, post,
    web::{self, Json},
};

use crate::{
    db::DB,
    models::{chat::ChatAndLastMessage, shared::UuidModel},
};

#[api_v2_operation]
#[post("/get_my_chats")]
pub async fn get_my_chats(
    db: web::Data<Mutex<DB>>,
    req: HttpRequest,
) -> Result<Json<Vec<ChatAndLastMessage>>, Error> {
    let ext = req.extensions();
    let user_uuid = ext.get::<UuidModel>().unwrap();
    let mut db = db.lock().await;
    let user = db.get_user_by_uuid(&user_uuid).map_err(|e| {
        println!("Failed to get user by uuid {:?}", e);
        actix_web::error::ErrorInternalServerError("Failed to get user by uuid")
    })?;

    let chats = user.get_chats(&mut db).map_err(|e| {
        println!("Failed to get chats {:?}", e);
        actix_web::error::ErrorInternalServerError("Failed to get chats")
    })?;

    let chats_with_last_messages = chats
        .into_iter()
        .map(|chat| {
            let last_message = chat.get_last_message(&mut db).map_err(|e| {
                println!("Failed to get last message {:?}", e);
                actix_web::error::ErrorInternalServerError("Failed to get last message")
            })?;
            Ok::<ChatAndLastMessage, Error>(ChatAndLastMessage { chat, last_message })
        })
        .collect::<Result<Vec<_>, _>>()?;

    Ok(Json(chats_with_last_messages))
}
