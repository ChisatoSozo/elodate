use std::error::Error;
//TODO: encryption at rest

use crate::{db::DB, models::internal_models::internal_user::Notification};

use super::{
    internal_chat::InternalChat,
    internal_image::InternalImage,
    internal_user::InternalUser,
    shared::{Bucket, InternalUuid},
};

#[derive(Debug, Clone, rkyv::Archive, rkyv::Serialize, rkyv::Deserialize)]
#[archive(compare(PartialEq), check_bytes)]
pub struct InternalMessage {
    pub uuid: InternalUuid<InternalMessage>,
    pub sent_at: i64,
    pub edited: bool,
    pub author: InternalUuid<InternalUser>,
    pub content: String,
    pub image: Option<InternalUuid<InternalImage>>,
    pub read_by: Vec<InternalUuid<InternalUser>>,
    pub chat: InternalUuid<InternalChat>,
}

impl InternalMessage {
    pub fn save(
        self,
        chat: &mut InternalChat,
        db: &DB,
    ) -> Result<InternalUuid<InternalMessage>, Box<dyn Error>> {
        //does the chat already have this message?
        if !chat.messages.contains(&self.uuid) {
            chat.messages.push(self.uuid.clone());
            chat.most_recent_message = match self.content.len() {
                0 => match self.image {
                    Some(_) => "Sent an image".to_string(),
                    None => "Sent an empty message (somehow)".to_string(),
                },
                _ => self.content.clone(),
            };
            chat.most_recent_sender = Some(self.author.clone());
            chat.unread = chat
                .users
                .iter()
                .enumerate()
                .map(|(i, u)| {
                    if u == &self.author {
                        0
                    } else {
                        chat.unread[i] + 1
                    }
                })
                .collect();
            chat.uuid.write(&chat, db)?;
        };

        //notify all other users in chat
        for user in chat.users.iter() {
            if user != &self.author {
                let user: InternalUuid<InternalUser> = user.clone();
                let mut user = user
                    .load(db)?
                    .ok_or("User not found in save internal message")?;
                user.notifications
                    .push(Notification::UnreadMessage(self.uuid.clone()));
                user.uuid.write(&user, db)?;
            }
        }

        self.uuid.write(&self, db)
    }
}

//TODO: probably bad logic here
impl InternalMessage {
    pub fn save_ref_do_not_use_unless_its_that_one_weird_message_place(
        &self,
        db: &DB,
    ) -> Result<(), Box<dyn Error>> {
        self.uuid.write(&self, db)?;
        Ok(())
    }
}

impl Bucket for InternalMessage {
    fn bucket() -> &'static str {
        "messages"
    }
}
