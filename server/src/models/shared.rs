use paperclip::actix::Apiv2Schema;
use serde::{Deserialize, Serialize};
use std::{
    fmt::{self, Display, Formatter},
    hash::{Hash, Hasher},
};
use uuid::Uuid;

#[derive(Debug, Serialize, Deserialize, Apiv2Schema, Clone)]
pub struct UuidModel(pub String);

impl UuidModel {
    pub fn new() -> Self {
        UuidModel(Uuid::new_v4().to_string())
    }
}

impl Display for UuidModel {
    fn fmt(&self, f: &mut Formatter) -> fmt::Result {
        write!(f, "{}", self.0)
    }
}

//from and to bytes for serde_cbor
impl From<UuidModel> for [u8; 16] {
    fn from(uuid: UuidModel) -> Self {
        let uuid = Uuid::parse_str(&uuid.0).unwrap();
        uuid.as_bytes().to_owned()
    }
}

impl From<[u8; 16]> for UuidModel {
    fn from(bytes: [u8; 16]) -> Self {
        let uuid = Uuid::from_bytes(bytes);
        UuidModel(uuid.to_string())
    }
}

impl Eq for UuidModel {}
impl PartialEq for UuidModel {
    fn eq(&self, other: &Self) -> bool {
        self.0 == other.0
    }
}

impl Hash for UuidModel {
    fn hash<H: Hasher>(&self, state: &mut H) {
        self.0.hash(state);
    }
}
