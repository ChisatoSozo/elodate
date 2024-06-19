use crate::{
    db::DB,
    models::{
        api_models::api_chat::ApiChat,
        internal_models::{internal_user::InternalUser, shared::InternalUuid},
    },
};

use super::bot_actions::post_with_jwt;
//TODO: jwt refresh
pub fn send_and_respond_to_chats(
    client: &reqwest::blocking::Client,
    db: &DB,
    uuid_jwt: &(String, String),
    me: &InternalUser,
    host: &str,
) -> Result<(), Box<dyn std::error::Error>> {
    let chat_uuids = me
        .chats
        .iter()
        .map(|chat| chat.id.clone())
        .collect::<Vec<_>>();
    let chats_string = serde_json::to_string(&chat_uuids)?;

    let chats = post_with_jwt(
        host,
        client,
        &"get_chats".to_string(),
        &uuid_jwt.1,
        chats_string,
    );

    match chats {
        Ok(chats) => {
            for chat in chats.as_array().ok_or("Error fetching chats")? {
                let chat: ApiChat = serde_json::from_value(chat.clone())?;
                let internal_chat_uuid: InternalUuid<_> = chat.uuid.clone().into();
                let internal_chat = internal_chat_uuid.load(db)?.ok_or("Chat not found")?;

                if internal_chat.most_recent_sender == Some(me.uuid.clone()) {
                    continue;
                }

                let likelihood_to_message;

                if internal_chat.most_recent_sender.is_none() {
                    likelihood_to_message = me
                        .bot_props
                        .as_ref()
                        .ok_or(format!("Bot props not found for user: {}", me.username))?
                        .likelihood_to_send_message;
                } else {
                    likelihood_to_message = me
                        .bot_props
                        .as_ref()
                        .ok_or(format!("Bot props not found for user: {}", me.username))?
                        .likelihood_to_respond_to_message;
                }

                let should_respond = rand::random::<f64>() < likelihood_to_message as f64;

                if should_respond {
                    let _ = post_with_jwt(
                        host,
                        client,
                        &"send_message".to_string(),
                        &uuid_jwt.1,
                        format!(
                            r#"{{"chat_uuid":"{}","message":{{
                                "content":"Hello!"
                            }}}}"#,
                            chat.uuid.id
                        ),
                    )?;
                }
            }
        }
        Err(e) => {
            println!("Error fetching chats: {:?}", e);
        }
    }
    Ok(())
}
