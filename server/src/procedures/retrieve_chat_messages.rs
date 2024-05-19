use std::error::Error;

use crate::{
    db::DB,
    models::{message::Message, shared::UuidModel, user::User},
};

pub fn retrieve_chat_messages(
    chat_uuid: UuidModel,
    user: User,
    db: &mut DB,
) -> Result<Vec<Message>, Box<dyn Error>> {
    let mut chat = db.get_chat(&chat_uuid).map_err(|e| {
        println!("Failed to get chat {:?}", e);
        actix_web::error::ErrorInternalServerError("Failed to get chat")
    })?;

    let messages = chat.get_messages(db).map_err(|e| {
        println!("Failed to get messages {:?}", e);
        actix_web::error::ErrorInternalServerError("Failed to get messages")
    })?;

    let mut did_update = false;

    let new_messages = messages
        .into_iter()
        .map(|mut message| {
            if message.author != user.uuid {
                if message.reciever_read == false {
                    did_update = true;
                }
                message.reciever_read = true;
            }
            message
        })
        .collect::<Vec<Message>>();

    if chat.user1 == user.uuid {
        if chat.user1_unread > 0 {
            did_update = true;
        }
        chat.user1_unread = 0;
    } else {
        if chat.user2_unread > 0 {
            did_update = true;
        }
        chat.user2_unread = 0;
    }

    if did_update {
        db.insert_chat(&chat).map_err(|e| {
            println!("Failed to update chat {:?}", e);
            actix_web::error::ErrorInternalServerError("Failed to update chat")
        })?;

        for message in &new_messages {
            db.insert_message(message).map_err(|e| {
                println!("Failed to insert message {:?}", e);
                actix_web::error::ErrorInternalServerError("Failed to insert message")
            })?;
        }
    }

    let messages_with_images = new_messages
        .into_iter()
        .map(|mut message| {
            message.fill_image(&chat, &user, db).map_err(|e| {
                println!("Failed to fill image {:?}", e);
                actix_web::error::ErrorInternalServerError("Failed to fill image")
            })?;
            Ok(message)
        })
        .collect::<Result<Vec<Message>, Box<dyn Error>>>()?;

    Ok(messages_with_images)
}
