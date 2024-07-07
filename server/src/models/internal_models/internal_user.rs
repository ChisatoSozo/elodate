use crate::vec::shared::VectorSearch;
use std::error::Error;

//TODO: recalc age on day change

use super::{
    internal_chat::InternalChat,
    internal_image::InternalImage,
    internal_message::InternalMessage,
    internal_prefs::{LabeledPreferenceRange, LabeledProperty},
    internal_prefs_config::PREFS_CONFIG,
    shared::{GetBbox, GetVector, Insertable, InternalUuid, Save},
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
pub enum Action {
    SendMessage,
    RecieveMessage,
    Rate,
}

#[derive(Debug, Clone, rkyv::Serialize, rkyv::Deserialize, rkyv::Archive)]
#[archive(compare(PartialEq), check_bytes)]
pub struct TimestampedAction {
    pub action: Action,
    pub timestamp: i64,
}

#[derive(Debug, Clone, rkyv::Serialize, rkyv::Deserialize, rkyv::Archive)]
#[archive(compare(PartialEq), check_bytes)]
pub enum Notification {
    UnreadMessage(InternalUuid<InternalMessage>),
    Match(InternalUuid<InternalUser>),
    System(String),
}

#[derive(Debug, Clone, rkyv::Serialize, rkyv::Deserialize, rkyv::Archive)]
#[archive(compare(PartialEq), check_bytes)]
pub struct BotProps {
    pub likelihood_to_swipe_right: f32,
    pub likelihood_to_recieve_like: f32,
    pub likelihood_to_send_message: f32,
    pub likelihood_to_respond_to_message: f32,
}

impl BotProps {
    pub fn gen() -> Self {
        Self {
            likelihood_to_swipe_right: rand::random(),
            likelihood_to_recieve_like: rand::random(),
            likelihood_to_send_message: rand::random(),
            likelihood_to_respond_to_message: rand::random(),
        }
    }
}

#[derive(Debug, rkyv::Serialize, rkyv::Deserialize, rkyv::Archive)]
#[archive(compare(PartialEq), check_bytes)]
pub struct InternalUser {
    pub uuid: InternalUuid<InternalUser>,
    pub hashed_password: String,
    pub elo: f32,
    pub ratings: Vec<InternalRating>,
    pub seen: Vec<InternalUuid<InternalUser>>,
    pub chats: Vec<InternalUuid<InternalChat>>,
    pub images: Vec<InternalUuid<InternalImage>>,
    pub preview_image: Option<InternalUuid<InternalImage>>,
    pub username: String,
    pub display_name: String,
    pub description: String,
    pub birthdate: i64,
    pub prefs: Vec<LabeledPreferenceRange>,
    pub props: Vec<LabeledProperty>,
    pub owned_images: Vec<InternalUuid<InternalImage>>,
    pub actions: Vec<TimestampedAction>,
    pub notifications: Vec<Notification>,
    pub published: bool,
    pub bot_props: Option<BotProps>,
    pub is_admin: bool,
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

    pub fn publishable_msg(&self) -> String {
        if self.images.len() < 1 {
            return "You must have at least one image".to_string();
        }
        if self.preview_image.is_none() {
            return "You must have a preview image".to_string();
        }
        let mandatory_props = PREFS_CONFIG
            .iter()
            .filter(|p| p.non_optional_message.is_some())
            .map(|p| p.name)
            .collect::<Vec<_>>();

        for prop in mandatory_props {
            if !self.props.iter().any(|p| p.name == prop) {
                return format!("You must have the property {}", prop);
            }
            //are any of the props -32768?
            if self
                .props
                .iter()
                .any(|p| p.value == -32768 && p.name == prop)
            {
                return format!("You must set a value for the property {}", prop);
            }
        }
        "".to_string()
    }
}

impl Insertable for InternalUser {
    fn version() -> u64 {
        1
    }
}

impl Save for InternalUser {
    fn save(self, db: &DB) -> Result<InternalUuid<InternalUser>, Box<dyn Error>> {
        db.write_index("users.username", &self.username, &self.uuid)?;
        self.uuid.write(&self, db)?;
        let arc_clone = db.vec_index.clone();
        let mut lock = arc_clone.lock().map_err(|_| "Could not lock vec_index")?;

        if self.published {
            lock.add(&self.props.get_vector(), &self.uuid.id);
            lock.add_bbox(&self.prefs.get_bbox(), &self.uuid.id);
        } else {
            log::info!("User not published, not adding to vec index")
        }
        Ok(self.uuid)
    }
}

impl DB {
    pub fn get_user_by_username(
        &self,
        username: &String,
    ) -> Result<Option<InternalUser>, Box<dyn Error>> {
        let uuid = self.read_index::<InternalUser>("users.username", username)?;
        match uuid {
            Some(uuid) => uuid.load(self),
            None => Ok(None),
        }
    }
}
