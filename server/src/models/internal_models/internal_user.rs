use paperclip::{actix::Apiv2Schema, v2::schema::Apiv2Schema};

use crate::vec::shared::VectorSearch;
use std::error::Error;

//TODO: recalc age on day change

use super::{
    internal_chat::InternalChat,
    internal_image::InternalImage,
    internal_message::InternalMessage,
    internal_prefs::{LabeledPreferenceRange, LabeledProperty},
    internal_prefs_config::PREFS_CONFIG,
    migration::migration::get_admin_uuid,
    shared::{GetBbox, GetVector, Insertable, InternalUuid, Save},
};

use crate::db::DB;

#[derive(Debug, Clone, rkyv::Serialize, rkyv::Deserialize, rkyv::Archive)]
#[archive(compare(PartialEq), check_bytes)]
pub enum InternalRating {
    LikedBy(InternalUuid<InternalUser>),
    PassedBy(InternalUuid<InternalUser>),
}

#[derive(Debug, serde::Serialize, paperclip::actix::Apiv2Schema)]
pub struct SerializableInternalRating {
    pub enum_type: String,
    pub uuid: String,
}

impl InternalRating {
    pub fn to_serializable(&self) -> SerializableInternalRating {
        match self {
            InternalRating::LikedBy(uuid) => SerializableInternalRating {
                enum_type: "LikedBy".to_string(),
                uuid: uuid.id.to_string(),
            },
            InternalRating::PassedBy(uuid) => SerializableInternalRating {
                enum_type: "PassedBy".to_string(),
                uuid: uuid.id.to_string(),
            },
        }
    }
}

impl serde::Serialize for InternalRating {
    fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
    where
        S: serde::ser::Serializer,
    {
        self.to_serializable().serialize(serializer)
    }
}

impl Apiv2Schema for InternalRating {
    fn name() -> Option<String> {
        SerializableInternalRating::name()
    }

    fn description() -> &'static str {
        SerializableInternalRating::description()
    }

    fn required() -> bool {
        SerializableInternalRating::required()
    }

    fn raw_schema() -> paperclip::v2::models::DefaultSchemaRaw {
        SerializableInternalRating::raw_schema()
    }

    fn schema_with_ref() -> paperclip::v2::models::DefaultSchemaRaw {
        SerializableInternalRating::schema_with_ref()
    }

    fn security_scheme() -> Option<paperclip::v2::models::SecurityScheme> {
        SerializableInternalRating::security_scheme()
    }

    fn header_parameter_schema(
    ) -> Vec<paperclip::v2::models::Parameter<paperclip::v2::models::DefaultSchemaRaw>> {
        SerializableInternalRating::header_parameter_schema()
    }
}

#[derive(Debug, Clone, rkyv::Serialize, rkyv::Deserialize, rkyv::Archive)]
#[archive(compare(PartialEq), check_bytes)]
pub enum Action {
    SendMessage,
    RecieveMessage,
    Rate,
}

#[derive(Debug, serde::Serialize, paperclip::actix::Apiv2Schema)]
pub struct SerializableAction {
    pub enum_type: String,
}

impl Action {
    pub fn to_serializable(&self) -> SerializableAction {
        match self {
            Action::SendMessage => SerializableAction {
                enum_type: "SendMessage".to_string(),
            },
            Action::RecieveMessage => SerializableAction {
                enum_type: "RecieveMessage".to_string(),
            },
            Action::Rate => SerializableAction {
                enum_type: "Rate".to_string(),
            },
        }
    }
}

impl serde::Serialize for Action {
    fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
    where
        S: serde::ser::Serializer,
    {
        self.to_serializable().serialize(serializer)
    }
}

impl Apiv2Schema for Action {
    fn name() -> Option<String> {
        SerializableAction::name()
    }

    fn description() -> &'static str {
        SerializableAction::description()
    }

    fn required() -> bool {
        SerializableAction::required()
    }

    fn raw_schema() -> paperclip::v2::models::DefaultSchemaRaw {
        SerializableAction::raw_schema()
    }

    fn schema_with_ref() -> paperclip::v2::models::DefaultSchemaRaw {
        SerializableAction::schema_with_ref()
    }

    fn security_scheme() -> Option<paperclip::v2::models::SecurityScheme> {
        SerializableAction::security_scheme()
    }

    fn header_parameter_schema(
    ) -> Vec<paperclip::v2::models::Parameter<paperclip::v2::models::DefaultSchemaRaw>> {
        SerializableAction::header_parameter_schema()
    }
}

#[derive(
    Debug,
    Clone,
    rkyv::Serialize,
    rkyv::Deserialize,
    rkyv::Archive,
    serde::Serialize,
    paperclip::actix::Apiv2Schema,
)]
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

#[derive(serde::Serialize, Apiv2Schema)]
pub struct SerializableNotification {
    pub enum_type: String,
    pub message: String,
    pub uuid: String,
}

impl Notification {
    pub fn to_serializable(&self) -> SerializableNotification {
        match self {
            Notification::UnreadMessage(uuid) => SerializableNotification {
                enum_type: "UnreadMessage".to_string(),
                message: "".to_string(),
                uuid: uuid.id.to_string(),
            },
            Notification::Match(uuid) => SerializableNotification {
                enum_type: "Match".to_string(),
                message: "".to_string(),
                uuid: uuid.id.to_string(),
            },
            Notification::System(message) => SerializableNotification {
                enum_type: "System".to_string(),
                message: message.clone(),
                uuid: "".to_string(),
            },
        }
    }
}

impl serde::Serialize for Notification {
    fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
    where
        S: serde::ser::Serializer,
    {
        self.to_serializable().serialize(serializer)
    }
}

impl Apiv2Schema for Notification {
    fn name() -> Option<String> {
        SerializableNotification::name()
    }

    fn description() -> &'static str {
        SerializableNotification::description()
    }

    fn required() -> bool {
        SerializableNotification::required()
    }

    fn raw_schema() -> paperclip::v2::models::DefaultSchemaRaw {
        SerializableNotification::raw_schema()
    }

    fn schema_with_ref() -> paperclip::v2::models::DefaultSchemaRaw {
        SerializableNotification::schema_with_ref()
    }

    fn security_scheme() -> Option<paperclip::v2::models::SecurityScheme> {
        SerializableNotification::security_scheme()
    }

    fn header_parameter_schema(
    ) -> Vec<paperclip::v2::models::Parameter<paperclip::v2::models::DefaultSchemaRaw>> {
        SerializableNotification::header_parameter_schema()
    }
}

#[derive(
    Debug,
    Clone,
    rkyv::Serialize,
    rkyv::Deserialize,
    rkyv::Archive,
    serde::Serialize,
    paperclip::actix::Apiv2Schema,
)]
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

#[derive(
    Debug,
    rkyv::Serialize,
    rkyv::Deserialize,
    rkyv::Archive,
    serde::Serialize,
    paperclip::actix::Apiv2Schema,
)]
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
}

impl InternalUser {
    pub fn is_liked_by(&self, user: &InternalUuid<InternalUser>) -> bool {
        self.ratings.iter().any(|rating| match rating {
            InternalRating::LikedBy(uuid) => uuid == user,
            _ => false,
        })
    }

    pub fn is_admin(&self) -> bool {
        self.uuid == get_admin_uuid()
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

    pub fn delete(&self, db: &DB) -> Result<(), Box<dyn Error>> {
        db.delete_index("users.username", &self.username)?;
        self.uuid.clone().delete(db)?;
        let arc_clone = db.vec_index.clone();
        let mut lock = arc_clone.lock().map_err(|_| "Could not lock vec_index")?;
        lock.remove(&self.uuid.id);
        lock.remove_bbox(&self.uuid.id);
        Ok(())
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
    pub fn get_admin(&self) -> Result<InternalUser, Box<dyn Error>> {
        let uuid = get_admin_uuid();
        uuid.load(self)?.ok_or("Admin not found".into())
    }
}
