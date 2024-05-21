use std::error::Error;

use crate::db::DB;

use super::shared::InternalUuid;
use super::{internal_message::InternalMessage, internal_user::InternalUser};

#[derive(Debug, Clone, rkyv::Archive, rkyv::Serialize, rkyv::Deserialize)]
#[archive(compare(PartialEq), check_bytes)]
pub struct InternalChat {
    pub uuid: InternalUuid<InternalChat>,
    pub users: Vec<InternalUuid<InternalUser>>,
    pub unread: Vec<u32>, //same order as users
    pub messages: Vec<InternalUuid<InternalMessage>>,
    pub most_recent_message: String,
}

impl InternalChat {
    pub fn new(users: Vec<InternalUuid<InternalUser>>) -> InternalChat {
        let users_len = users.len();
        InternalChat {
            uuid: InternalUuid::<InternalChat>::new(),
            users,
            unread: vec![0; users_len],
            messages: vec![],
            most_recent_message: "No messages yet".to_string(),
        }
    }
}

impl InternalChat {
    pub fn save(&self, db: &DB) -> Result<InternalUuid<InternalChat>, Box<dyn Error>> {
        db.write_object(&self.uuid, self)
    }
}
