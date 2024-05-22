use image::{GenericImageView, ImageFormat};
use paperclip::actix::Apiv2Schema;
use serde::{Deserialize, Serialize};

use crate::models::internal_models::internal_image::Access;
use crate::models::internal_models::internal_user::InternalUser;
use crate::models::internal_models::shared::InternalUuid;

use super::super::internal_models::internal_image::InternalImage;
use super::shared::ApiUuid;
use std::io::Cursor;

#[derive(
    Debug,
    Clone,
    Serialize,
    Deserialize,
    Apiv2Schema,
    rkyv::Archive,
    rkyv::Serialize,
    rkyv::Deserialize,
    PartialEq,
)]
#[archive(compare(PartialEq), check_bytes)]
pub enum EloDateImageFormat {
    Png,
    Jpeg,
    Gif,
    WebP,
    Pnm,
    Tiff,
    Tga,
    Dds,
    Bmp,
    Ico,
    Hdr,
    OpenExr,
    Farbfeld,
    Avif,
    Qoi,
}

impl Into<ImageFormat> for EloDateImageFormat {
    fn into(self) -> ImageFormat {
        match self {
            EloDateImageFormat::Png => ImageFormat::Png,
            EloDateImageFormat::Jpeg => ImageFormat::Jpeg,
            EloDateImageFormat::Gif => ImageFormat::Gif,
            EloDateImageFormat::WebP => ImageFormat::WebP,
            EloDateImageFormat::Pnm => ImageFormat::Pnm,
            EloDateImageFormat::Tiff => ImageFormat::Tiff,
            EloDateImageFormat::Tga => ImageFormat::Tga,
            EloDateImageFormat::Dds => ImageFormat::Dds,
            EloDateImageFormat::Bmp => ImageFormat::Bmp,
            EloDateImageFormat::Ico => ImageFormat::Ico,
            EloDateImageFormat::Hdr => ImageFormat::Hdr,
            EloDateImageFormat::OpenExr => ImageFormat::OpenExr,
            EloDateImageFormat::Farbfeld => ImageFormat::Farbfeld,
            EloDateImageFormat::Avif => ImageFormat::Avif,
            EloDateImageFormat::Qoi => ImageFormat::Qoi,
        }
    }
}

#[derive(Debug, Clone, Deserialize, Apiv2Schema)]
pub struct ApiImageWritable {
    pub b64_content: String,
    pub image_type: EloDateImageFormat,
}

impl ApiImageWritable {
    pub fn to_internal(self, access: Access) -> Result<InternalImage, Box<dyn std::error::Error>> {
        #[allow(deprecated)]
        let content = base64::decode(&self.b64_content)?;
        let img = image::load_from_memory_with_format(&content, self.image_type.into())?;

        // Crop to rectangle with largest area that fits in 1:2 aspect ratio and max 500x1000 pixels
        let (width, height) = img.dimensions();
        let (new_width, new_height) = if width as f32 / height as f32 > 1.0 / 2.0 {
            (height * 2, height)
        } else {
            (width, width / 2)
        };

        let img = img.resize(new_width, new_height, image::imageops::FilterType::Lanczos3);

        //save image to new buffer as webp with lowest quality that still looks good
        let mut buf = Vec::new();
        //use cursor
        let mut cursor = Cursor::new(&mut buf);
        img.write_to(&mut cursor, ImageFormat::WebP)?;

        Ok(InternalImage {
            uuid: InternalUuid::new(),
            content: buf,
            access,
        })
    }
}

#[derive(Debug, Clone, Serialize, Apiv2Schema)]
pub struct ApiImage {
    pub uuid: ApiUuid<InternalImage>,
    pub b64_content: String,
}

impl ApiImage {
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
