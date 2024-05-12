use fake::Dummy;
use paperclip::actix::Apiv2Schema;
use serde::{Deserialize, Serialize};

use super::shared::UuidModel;

#[derive(Debug, Serialize, Deserialize, Apiv2Schema, Clone, PartialEq, Eq, Dummy)]
pub enum Rated {
    LikedBy(UuidModel),
    PassedBy(UuidModel),
}

#[derive(Debug, Serialize, Deserialize, Apiv2Schema, Clone, PartialEq, Eq, Dummy)]
pub enum Rating {
    Like,
    Pass,
}

#[derive(Debug, Serialize, Deserialize, Apiv2Schema, Clone, PartialEq, Eq, Dummy)]
pub struct RatingWithTarget {
    pub rating: Rating,
    pub target: UuidModel,
}
