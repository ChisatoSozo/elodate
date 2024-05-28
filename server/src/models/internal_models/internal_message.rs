use std::error::Error;
//TODO: encryption at rest

use crate::db::DB;

use super::{
    internal_chat::InternalChat, internal_image::InternalImage, internal_user::InternalUser,
    shared::InternalUuid,
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
            chat.save(db)?;
        };
        db.write_object(&self.uuid, &self)
    }
}

//TODO: probably bad logic here
impl InternalMessage {
    pub fn save_ref_do_not_use_unless_its_that_one_weird_message_place(
        &self,
        db: &DB,
    ) -> Result<(), Box<dyn Error>> {
        db.write_object(&self.uuid, &self)?;
        Ok(())
    }
}
