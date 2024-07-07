use paperclip::actix::Apiv2Schema;
use serde::{Deserialize, Serialize};

use crate::models::internal_models::internal_image::Access;
use crate::models::internal_models::internal_user::InternalUser;
use crate::models::internal_models::shared::InternalUuid;
use crate::test::fake::Gen;

use super::super::internal_models::internal_image::InternalImage;
use super::shared::ApiUuid;

#[derive(Debug, Deserialize, Apiv2Schema)]
pub struct ApiImageWritable {
    pub content: Vec<u8>,
}

impl Gen<'_, bool> for ApiImageWritable {
    fn gen(_options: &bool) -> Self {
        //get bytes from test.jpeg in this src folder, it's not a string, so we can't use include_str!
        const TEST_IMG_BYTES: &[u8] = include_bytes!("test.jpeg");
        ApiImageWritable {
            #[allow(deprecated)]
            content: TEST_IMG_BYTES.to_vec(),
        }
    }
}

impl ApiImageWritable {
    pub fn new_admin() -> Self {
        //get bytes from test.jpeg in this src folder, it's not a string, so we can't use include_str!
        const ADMIN_IMG_BYTES: &[u8] = include_bytes!("admin.jpeg");
        ApiImageWritable {
            #[allow(deprecated)]
            content: ADMIN_IMG_BYTES.to_vec(),
        }
    }

    pub fn new(content: Vec<u8>) -> Self {
        Self { content }
    }

    pub fn to_internal(self, access: Access) -> Result<InternalImage, Box<dyn std::error::Error>> {
        #[allow(deprecated)]
        let content = self.content;

        Ok(InternalImage {
            uuid: InternalUuid::new(),
            content,
            access,
        })
    }
}

#[derive(Debug, Serialize, Apiv2Schema)]
pub struct ApiImage {
    pub uuid: ApiUuid<InternalImage>,
    pub content: String,
}

impl ApiImage {
    pub fn from_internal(
        image: InternalImage,
        user: Option<&InternalUser>,
    ) -> Result<Self, Box<dyn std::error::Error>> {
        match image.access {
            Access::Everyone => (),
            Access::UserList(user_list) => {
                if user.is_none() {
                    return Err("User does not have access to image".into());
                }
                if !user_list.contains(&user.unwrap().uuid) {
                    return Err("User does not have access to image".into());
                }
            }
        }

        #[allow(deprecated)]
        let b64_content = base64::encode(&image.content);

        Ok(Self {
            uuid: image.uuid.into(),
            content: b64_content,
        })
    }
}
