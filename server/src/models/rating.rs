use paperclip::actix::Apiv2Schema;
use serde::{Deserialize, Serialize};

use super::shared::UuidModel;

#[derive(Debug, Serialize, Deserialize, Apiv2Schema, Clone, PartialEq, Eq)]
pub enum Rated {
    LikedBy(UuidModel),
    PassedBy(UuidModel),
}

#[derive(Debug, Serialize, Deserialize, Apiv2Schema, Clone, PartialEq, Eq)]
pub enum Rating {
    Like,
    Pass,
}

#[derive(Debug, Serialize, Deserialize, Apiv2Schema, Clone, PartialEq, Eq)]
pub struct RatingWithTarget {
    pub rating: Rating,
    pub target: UuidModel,
}
