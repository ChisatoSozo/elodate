use std::{error::Error, io::Cursor};

use image::{imageops::crop, GenericImageView, ImageFormat};

use super::{
    internal_user::InternalUser,
    shared::{Bucket, InternalUuid, Save},
};

use crate::db::DB;

#[derive(Debug, Clone, rkyv::Archive, rkyv::Serialize, rkyv::Deserialize)]
#[archive(compare(PartialEq), check_bytes)]
pub enum Access {
    Everyone,
    UserList(Vec<InternalUuid<InternalUser>>),
}

impl Access {
    pub fn can_access(&self, user_uuid: &InternalUuid<InternalUser>) -> bool {
        match self {
            Access::Everyone => true,
            Access::UserList(users) => users.iter().any(|u| u == user_uuid),
        }
    }
}

#[derive(Debug, Clone, rkyv::Archive, rkyv::Serialize, rkyv::Deserialize)]
#[archive(compare(PartialEq), check_bytes)]
pub struct InternalImage {
    pub uuid: InternalUuid<InternalImage>,
    pub content: Vec<u8>,
    pub access: Access,
}

impl InternalImage {
    pub fn to_preview(self, access: Access) -> Result<InternalImage, Box<dyn std::error::Error>> {
        //same as to_internal, but crop and resize to 128x128
        #[allow(deprecated)]
        let content = self.content;
        let mut img = image::load_from_memory_with_format(&content, ImageFormat::Jpeg)?;

        //crop to 128:128 aspect ratio, crop width if it's too wide, crop height if it's too tall, for any crop, center the crop
        //then resize to 128x128

        let (width, height) = img.dimensions();
        let (new_width, new_height) = if width as f32 / height as f32 > 128.0 / 128.0 {
            //crop width
            let new_width = height * 128 / 128;
            (new_width, height)
        } else {
            //crop height
            let new_height = width * 128 / 128;
            (width, new_height)
        };

        //crop_and_resize isn't a thing, so we have to do it in two steps, crop x and y are the top left corner of the crop
        let img = crop(
            &mut img,
            (width - new_width) / 2,
            (height - new_height) / 2,
            new_width,
            new_height,
        );

        //convert subimage to image
        let img = img.to_image();
        //convert image buffer to image
        let img: image::DynamicImage = img.into();

        let img = img.resize(128, 128, image::imageops::FilterType::Lanczos3);

        //save image to new buffer as jpg with lowest quality that still looks good
        let mut buf = Vec::new();

        //use cursor
        let mut cursor = Cursor::new(&mut buf);
        img.into_rgb8().write_to(&mut cursor, ImageFormat::Jpeg)?;

        Ok(InternalImage {
            uuid: InternalUuid::new(),
            content: buf,
            access,
        })
    }
}

impl Save for InternalImage {
    fn save(self, db: &DB) -> Result<InternalUuid<InternalImage>, Box<dyn Error>> {
        self.uuid.write(&self, db)
    }
}

impl Bucket for InternalImage {
    fn bucket() -> &'static str {
        "image"
    }
}
