use paperclip::actix::Apiv2Schema;
use serde::{Deserialize, Serialize};

use crate::models::{api_models::shared::ApiUuid, internal_models::internal_user::InternalUser};

#[derive(Debug, Serialize, Deserialize, Apiv2Schema, Clone, PartialEq, Eq)]
pub struct Jwt {
    pub jwt: String,
    pub uuid: ApiUuid<InternalUser>,
}
