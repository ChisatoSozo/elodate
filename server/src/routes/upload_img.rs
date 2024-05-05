use std::sync::Mutex;

use actix_web::Error;
use actix_web::HttpMessage;
use base64::{engine::general_purpose, Engine};
use paperclip::actix::{
    api_v2_operation, post,
    web::{self, Json},
    Apiv2Schema,
};
use serde::{Deserialize, Serialize};

use crate::db::DB;
use crate::models::shared::UuidModel;
use crate::routes::common::Jwt;

#[derive(Debug, Serialize, Deserialize, Apiv2Schema, Clone, PartialEq, Eq)]
struct UploadImageInput {
    img_type: String,
    image_b64: String,
}

#[derive(Debug, Serialize, Deserialize, Apiv2Schema, Clone, PartialEq, Eq)]
struct UploadImageOutput {
    success: bool,
}

const VALID_IMAGE_TYPES: [&str; 4] = ["png", "jpeg", "jpg", "webp"];

enum ImageType {
    PNG,
    JPEG,
    JPG,
    WEBP,
}

impl TryFrom<&str> for ImageType {
    type Error = &'static str;

    fn try_from(value: &str) -> Result<Self, Self::Error> {
        match value {
            "png" => Ok(ImageType::PNG),
            "jpeg" => Ok(ImageType::JPEG),
            "jpg" => Ok(ImageType::JPG),
            "webp" => Ok(ImageType::WEBP),
            _ => Err("Invalid image type"),
        }
    }
}

#[api_v2_operation]
#[post("/upload_img")]
async fn upload_img(
    //db, req, and body are all passed in by Actix Web
    db: web::Data<Mutex<DB>>,
    body: Json<UploadImageInput>,
    req: web::HttpRequest,
) -> Result<Json<UploadImageOutput>, Error> {
    let user = body.into_inner();
    let uuid = req
        .extensions()
        .get::<UuidModel>()
        .ok_or_else(|| actix_web::error::ErrorUnauthorized("Missing JWT stored UUID"))?;

    //supress deprecation warning
    #[allow(deprecated)]
    let image_bytes = base64::decode(user.image_b64)
        .map_err(|_| actix_web::error::ErrorBadRequest("Failed to decode base64 image"))?;

    todo!("Check if image is valid");

    // return Ok(Json(UploadImageOutput { success: true }));
}
