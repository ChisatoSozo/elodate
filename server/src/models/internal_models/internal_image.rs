use std::error::Error;

use super::{
    internal_user::InternalUser,
    shared::{Bucket, InternalUuid, Save},
};

use crate::db::DB;

#[derive(Debug, Clone, rkyv::Archive, rkyv::Serialize, rkyv::Deserialize)]
#[archive(compare(PartialEq), check_bytes)]
pub enum Access {
    Everyone,
    UserList(Vec<InternalUuid<InternalUser>>),
}

impl Access {
    pub fn can_access(&self, user_uuid: &InternalUuid<InternalUser>) -> bool {
        match self {
            Access::Everyone => true,
            Access::UserList(users) => users.iter().any(|u| u == user_uuid),
        }
    }
}

#[derive(Debug, Clone, rkyv::Archive, rkyv::Serialize, rkyv::Deserialize)]
#[archive(compare(PartialEq), check_bytes)]
pub struct InternalImage {
    pub uuid: InternalUuid<InternalImage>,
    pub content: Vec<u8>,
    pub access: Access,
}

impl Save for InternalImage {
    fn save(self, db: &DB) -> Result<InternalUuid<InternalImage>, Box<dyn Error>> {
        self.uuid.write(&self, db)
    }
}

impl Bucket for InternalImage {}
