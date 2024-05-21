use std::error::Error;

use crate::{
    db::DB,
    models::internal_models::{
        internal_chat::InternalChat, internal_message::InternalMessage,
        internal_user::InternalUser, shared::InternalUuid,
    },
};

pub fn send_chat_message(
    chat_uuid: InternalUuid<InternalChat>,
    user: InternalUser,
    message: InternalMessage,
    db: &mut DB,
) -> Result<(), Box<dyn Error>> {
    let chat = chat_uuid.load(db).map_err(|e| {
        println!("Failed to get chat {:?}", e);
        actix_web::error::ErrorInternalServerError("Failed to get chat")
    })?;
    let mut chat = match chat {
        Some(chat) => chat,
        None => return Err(Box::new(actix_web::error::ErrorNotFound("Chat not found"))),
    };

    chat.add_message(message, &user, db)?;

    Ok(())
}
