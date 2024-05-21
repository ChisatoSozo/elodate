use paperclip::actix::Apiv2Schema;
use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize, PartialEq, Apiv2Schema)]
pub enum ApiRating {
    Like,
    Pass,
}
