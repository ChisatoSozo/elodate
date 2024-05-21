use super::super::internal_models::internal_image::InternalImage;
use super::shared::ApiUuid;
use serde::{Deserialize, Serialize};
use std::error::Error;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ApiImage {
    pub uuid: ApiUuid<ApiImage, InternalImage>,
    pub b64_content: String,
}

impl PartialEq for ApiImage {
    fn eq(&self, other: &Self) -> bool {
        self.uuid == other.uuid
    }
}

impl Eq for ApiImage {}

impl From<InternalImage> for ApiImage {
    fn from(image: InternalImage) -> Self {
        let b64 = base64::encode(&image.content);
        ApiImage {
            uuid: image.uuid.id.into(),
            b64_content: b64,
        }
    }
}
