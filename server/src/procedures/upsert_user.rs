use std::error::Error;
use validator::Validate;

use crate::{
    db::DB,
    models::{image::Image, user::User},
};

pub async fn upsert_user(
    user: &User,
    images: Vec<Image>,
    db: &mut DB,
) -> Result<User, Box<dyn Error>> {
    user.validate()
        .map_err(|e| actix_web::error::ErrorBadRequest(e))?;

    let image_ids = db.add_images_to_user(&user.uuid, &images).map_err(|e| {
        println!("Failed to add image to user {:?}", e);
        actix_web::error::ErrorInternalServerError("Failed to add image to user")
    })?;

    let user = User {
        images: image_ids,
        ..user.clone()
    };

    db.insert_user(&user).map_err(|e| {
        println!("Failed to insert user into database {:?}", e);
        actix_web::error::ErrorInternalServerError("Failed to insert user into database")
    })?;

    Ok(user)
}
