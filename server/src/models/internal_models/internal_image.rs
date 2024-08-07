use std::error::Error;

use super::{
    internal_user::InternalUser,
    shared::{Insertable, InternalUuid, Save},
};

use crate::db::DB;

#[derive(Debug, rkyv::Serialize, rkyv::Deserialize, rkyv::Archive, serde::Serialize, paperclip::actix::Apiv2Schema)]
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

#[derive(Debug, rkyv::Serialize, rkyv::Deserialize, rkyv::Archive, serde::Serialize, paperclip::actix::Apiv2Schema)]
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

impl Insertable for InternalImage {
    fn version() -> u64 {
        0
    }
}
