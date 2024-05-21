use std::error::Error;

use crate::models::internal_models::shared::Save;
use crate::{
    db::DB,
    models::internal_models::{
        internal_chat::InternalChat, internal_message::InternalMessage,
        internal_user::InternalUser, shared::InternalUuid,
    },
};

pub fn retrieve_chat_messages(
    chat_uuid: InternalUuid<InternalChat>,
    user: InternalUser,
    db: &mut DB,
) -> Result<Vec<InternalMessage>, Box<dyn Error>> {
    let chat = chat_uuid.load(db).map_err(|e| {
        println!("Failed to get chat {:?}", e);
        actix_web::error::ErrorInternalServerError("Failed to get chat")
    })?;
    let mut chat = match chat {
        Some(chat) => chat,
        None => return Err(Box::new(actix_web::error::ErrorNotFound("Chat not found"))),
    };

    let messages = chat.get_messages(db).map_err(|e| {
        println!("Failed to get messages {:?}", e);
        actix_web::error::ErrorInternalServerError("Failed to get messages")
    })?;

    let mut did_update = false;

    let new_messages = messages
        .into_iter()
        .map(|mut message| {
            if &message.author != &user.uuid {
                if message.read_by.contains(&user.uuid) {
                    return message;
                }
                message.read_by.push(user.uuid.clone());
            }
            message
        })
        .collect::<Vec<_>>();

    //update unread numbers
    for (i, message) in new_messages.iter().enumerate() {
        if message.author != user.uuid {
            chat.unread[i] = 0;
            did_update = true;
        }
    }

    if did_update {
        chat.save(db).map_err(|e| {
            println!("Failed to update chat {:?}", e);
            actix_web::error::ErrorInternalServerError("Failed to update chat")
        })?;

        for message in &new_messages {
            message
                .save_ref_do_not_use_unless_its_that_one_weird_message_place(db)
                .map_err(|e| {
                    println!("Failed to insert message {:?}", e);
                    actix_web::error::ErrorInternalServerError("Failed to insert message")
                })?;
        }
    }

    Ok(new_messages)
}
