use paperclip::actix::Apiv2Schema;
use serde::{Deserialize, Serialize};

// A trait that the Validate derive will impl
use validator::Validate;

use super::shared::UuidModel;

#[derive(Debug, Validate, Serialize, Deserialize, Apiv2Schema, Clone)]
pub struct Message {
    pub uuid: UuidModel,
    pub sent_at: i64,
    pub author: UuidModel,
    #[validate(length(min = 1, message = "Message content must not be empty"))]
    pub content: String,
}

impl Message {
    pub fn random_message(author: UuidModel) -> Message {
        Message {
            uuid: UuidModel::new(),
            sent_at: chrono::Utc::now().timestamp(),
            author,
            content: "Hello, world!".to_string(),
        }
    }
}
