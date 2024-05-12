use std::sync::Mutex;

use actix_web::Error;

use paperclip::actix::{
    api_v2_operation, post,
    web::{self, Json},
};

use crate::{
    db::DB,
    elo::elo_to_label,
    models::{shared::UuidModel, user::UserWithImagesAndElo},
};

#[api_v2_operation]
#[post("/get_user_with_single_image")]
pub async fn get_user_with_single_image(
    db: web::Data<Mutex<DB>>,
    body: Json<UuidModel>,
) -> Result<Json<UserWithImagesAndElo>, Error> {
    let user_uuid = body.into_inner();
    let mut db = db.lock().unwrap();
    let user = db.get_user_by_uuid(&user_uuid).map_err(|e| {
        println!("Failed to get user by uuid {:?}", e);
        actix_web::error::ErrorInternalServerError("Failed to get user by uuid")
    })?;

    let image = db.get_image_from_user(&user.uuid).map_err(|e| {
        println!("Failed to get image from user {:?}", e);
        actix_web::error::ErrorInternalServerError("Failed to get images from user")
    })?;

    let user_with_images = UserWithImagesAndElo {
        user: user.public,
        images: vec![image],
        elo: elo_to_label(user.elo),
    };

    Ok(Json(user_with_images))
}
