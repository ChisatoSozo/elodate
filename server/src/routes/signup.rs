use std::collections::HashSet;

use actix_web::Error;

use async_mutex::Mutex;
use bcrypt::hash;
use paperclip::actix::{
    api_v2_operation, post,
    web::{self, Json},
};

use crate::{
    constants::STARTING_ELO,
    db::DB,
    middleware::jwt::make_jwt,
    models::{
        shared::UuidModel,
        user::{User, UserWithImagesAndPassword},
    },
    procedures::upsert_user::upsert_user,
    routes::common::Jwt,
};

fn hash_password(password: &str) -> Result<String, bcrypt::BcryptError> {
    hash(password, 4)
}

#[api_v2_operation]
#[post("/signup")]
async fn signup(
    db: web::Data<Mutex<DB>>,
    body: Json<UserWithImagesAndPassword>,
) -> Result<Json<Jwt>, Error> {
    let mut db = db.lock().await;
    let inner = body.into_inner();
    let user = inner.user;
    let images = inner.images;
    let password = inner.password;

    let hashed_password = hash_password(&password).map_err(|e| {
        println!("Failed to hash password {:?}", e);
        actix_web::error::ErrorInternalServerError("Failed to hash password")
    })?;

    let user_exists = db.user_with_username_exists(&user.username).map_err(|e| {
        println!("Failed to check if user exists {:?}", e);
        actix_web::error::ErrorInternalServerError("Failed to check if user exists")
    })?;

    if user_exists {
        Err(actix_web::error::ErrorBadRequest("Username already taken"))?;
    }

    let user_with_uuid = User {
        uuid: UuidModel::new(),
        elo: STARTING_ELO,
        public: user,
        hashed_password,
        ratings: vec![],
        chats: vec![],
        images: vec![],
        seen: HashSet::new(),
    };

    upsert_user(&user_with_uuid, images, &mut db).await?;

    make_jwt(&user_with_uuid.uuid)
        .map(|jwt| Json(Jwt { jwt }))
        .map_err(|e| {
            println!("Failed to make jwt {:?}", e);
            actix_web::error::ErrorInternalServerError("Failed to make jwt")
        })
}
