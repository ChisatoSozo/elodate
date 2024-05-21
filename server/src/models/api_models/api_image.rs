use paperclip::actix::Apiv2Schema;
use serde::{Deserialize, Serialize};

use crate::models::internal_models::internal_image::Access;
use crate::models::internal_models::internal_user::InternalUser;

use super::super::internal_models::internal_image::InternalImage;
use super::shared::ApiUuid;

#[derive(Debug, Clone, Serialize, Deserialize, Apiv2Schema)]
pub struct ApiImage {
    pub uuid: ApiUuid<InternalImage>,
    pub b64_content: String,
}

impl PartialEq for ApiImage {
    fn eq(&self, other: &Self) -> bool {
        self.uuid == other.uuid
    }
}

impl Eq for ApiImage {}

impl ApiImage {
    pub fn to_internal(self, access: Access) -> InternalImage {
        #[allow(deprecated)]
        let content = base64::decode(&self.b64_content).unwrap();
        InternalImage {
            uuid: self.uuid.into(),
            content,
            access,
        }
    }

    pub fn from_internal(
        image: InternalImage,
        user: &InternalUser,
    ) -> Result<Self, Box<dyn std::error::Error>> {
        match image.access {
            Access::Everyone => (),
            Access::UserList(user_list) => {
                if !user_list.contains(&user.uuid) {
                    return Err("User does not have access to image".into());
                }
            }
        }

        #[allow(deprecated)]
        let b64 = base64::encode(&image.content);
        Ok(Self {
            uuid: image.uuid.into(),
            b64_content: b64,
        })
    }
}
