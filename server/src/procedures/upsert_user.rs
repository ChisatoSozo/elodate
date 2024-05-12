use bcrypt::hash;
use std::error::Error;
use validator::Validate;

use crate::{
    constants::STARTING_ELO,
    db::DB,
    models::{image::Image, shared::UuidModel, user::User},
};

fn hash_password(password: &str) -> Result<String, bcrypt::BcryptError> {
    hash(password, 4)
}

pub async fn upsert_user(
    user: &User,
    images: Vec<Image>,
    db: &mut DB,
) -> Result<User, Box<dyn Error>> {
    let user_exists = db.user_with_username_exists(&user.username).map_err(|e| {
        println!("Failed to check if user exists {:?}", e);
        actix_web::error::ErrorInternalServerError("Failed to check if user exists")
    })?;

    if user_exists {
        Err(actix_web::error::ErrorBadRequest("Username already taken"))?;
    }

    user.validate()
        .map_err(|e| actix_web::error::ErrorBadRequest(e))?;

    let mut image_ids = Vec::new();

    for image in images {
        //TODO: default to some image if image is invalid
        let image_id = db.add_image_to_user(&user, &image).await.map_err(|e| {
            println!("Failed to add image to user {:?}", e);
            actix_web::error::ErrorInternalServerError("Failed to add image to user")
        })?;
        image_ids.push(image_id);
    }

    let hashed_password = hash_password(&user.password).map_err(|e| {
        println!("Failed to hash password {:?}", e);
        actix_web::error::ErrorInternalServerError("Failed to hash password")
    })?;
    let user = User {
        uuid: UuidModel::new(),
        elo: STARTING_ELO,
        password: hashed_password,
        images: image_ids,
        ..user.clone()
    };

    db.insert_user(&user).map_err(|e| {
        println!("Failed to insert user into database {:?}", e);
        actix_web::error::ErrorInternalServerError("Failed to insert user into database")
    })?;

    Ok(user)
}
