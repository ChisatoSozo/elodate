use crate::vec::shared::VectorSearch;

use std::error::Error;

//TODO: recalc age on day change

use super::{
    internal_chat::InternalChat,
    internal_image::InternalImage,
    internal_preferences::{LabeledPreferenceRange, LabeledProperty},
    shared::{GetBbox, GetVector, InternalUuid, Save},
};

use crate::db::DB;

#[derive(Debug, Clone, rkyv::Serialize, rkyv::Deserialize, rkyv::Archive)]
#[archive(compare(PartialEq), check_bytes)]
pub enum InternalRating {
    LikedBy(InternalUuid<InternalUser>),
    PassedBy(InternalUuid<InternalUser>),
}

#[derive(Debug, Clone, rkyv::Serialize, rkyv::Deserialize, rkyv::Archive)]
#[archive(compare(PartialEq), check_bytes)]
pub struct InternalUser {
    pub uuid: InternalUuid<InternalUser>,
    pub hashed_password: String,
    pub elo: u32,
    pub ratings: Vec<InternalRating>,
    pub seen: Vec<InternalUuid<InternalUser>>,
    pub chats: Vec<InternalUuid<InternalChat>>,
    pub images: Vec<InternalUuid<InternalImage>>,
    pub preview_image: InternalUuid<InternalImage>,
    pub username: String,
    pub display_name: String,
    pub description: String,
    pub birthdate: i64,
    pub preferences: Vec<LabeledPreferenceRange>,
    pub properties: Vec<LabeledProperty>,
    pub owned_images: Vec<InternalUuid<InternalImage>>,
    pub published: bool,
}

impl InternalUser {
    pub fn is_liked_by(&self, user: &InternalUuid<InternalUser>) -> bool {
        self.ratings.iter().any(|rating| match rating {
            InternalRating::LikedBy(uuid) => uuid == user,
            _ => false,
        })
    }

    pub fn add_chat(&mut self, chat: &InternalChat) {
        self.chats.push(chat.uuid.clone());
    }

    pub fn get_chats(&self, db: &DB) -> Result<Vec<InternalChat>, Box<dyn Error>> {
        let mut chats = vec![];
        for chat_uuid in self.chats.iter() {
            let chat = chat_uuid.load(db)?;
            let chat = match chat {
                Some(chat) => chat,
                None => return Err("Chat not found".into()),
            };
            chats.push(chat);
        }
        Ok(chats)
    }
}

impl Save for InternalUser {
    fn save(self, db: &DB) -> Result<InternalUuid<InternalUser>, Box<dyn Error>> {
        db.write_index("user.username", &self.username, &self.uuid)?;
        db.write_object(&self.uuid, &self)?;
        let arc_clone = db.vec_index.clone();
        let mut lock = arc_clone.lock().map_err(|_| "Could not lock vec_index")?;

        lock.add(&self.properties.get_vector(), &self.uuid.id);
        lock.add_bbox(&self.preferences.get_bbox(), &self.uuid.id);
        Ok(self.uuid)
    }
}

impl DB {
    pub fn get_user_by_username(
        &self,
        username: &String,
    ) -> Result<Option<InternalUser>, Box<dyn Error>> {
        let uuid = self.read_index::<InternalUser>("user.username", username)?;
        match uuid {
            Some(uuid) => uuid.load(self),
            None => Ok(None),
        }
    }
}
