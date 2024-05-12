use paperclip::actix::Apiv2Schema;
use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize, Apiv2Schema, Clone)]
pub struct Success(pub String);
