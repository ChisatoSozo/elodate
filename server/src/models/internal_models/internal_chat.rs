use std::error::Error;

use crate::db::DB;

use super::shared::{Bucket, InternalUuid, Save};
use super::{internal_message::InternalMessage, internal_user::InternalUser};

#[derive(Debug, Clone, rkyv::Archive, rkyv::Serialize, rkyv::Deserialize)]
#[archive(compare(PartialEq), check_bytes)]
pub struct InternalChat {
    pub uuid: InternalUuid<InternalChat>,
    pub users: Vec<InternalUuid<InternalUser>>,
    pub unread: Vec<u32>, //same order as users
    pub messages: Vec<InternalUuid<InternalMessage>>,
    pub most_recent_message: String,
    pub most_recent_sender: Option<InternalUuid<InternalUser>>,
    pub most_recent_message_sent_at: i64,
}

impl InternalChat {
    pub fn new(users: Vec<InternalUuid<InternalUser>>) -> InternalChat {
        let users_len = users.len();
        let now = chrono::Utc::now().timestamp();
        InternalChat {
            uuid: InternalUuid::<InternalChat>::new(),
            users,
            unread: vec![0; users_len],
            messages: vec![],
            most_recent_message: "No messages yet".to_string(),
            most_recent_sender: None,
            most_recent_message_sent_at: now,
        }
    }
}

impl Save for InternalChat {
    fn save(self, db: &DB) -> Result<InternalUuid<InternalChat>, Box<dyn Error>> {
        self.uuid.write(&self, db)
    }
}

impl Bucket for InternalChat {}
