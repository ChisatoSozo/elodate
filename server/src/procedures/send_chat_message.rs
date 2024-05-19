use std::error::Error;

use crate::{
    db::DB,
    models::{message::Message, shared::UuidModel, user::User},
};

pub fn send_chat_message(
    chat_uuid: UuidModel,
    user: User,
    message: Message,
    db: &mut DB,
) -> Result<(), Box<dyn Error>> {
    let mut chat = db.get_chat(&chat_uuid).map_err(|e| {
        println!("Failed to get chat {:?}", e);
        actix_web::error::ErrorInternalServerError("Failed to get chat")
    })?;

    chat.add_message(message, &user, db)?;

    Ok(())
}
