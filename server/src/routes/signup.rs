use std::sync::Mutex;

use actix_web::Error;
use bcrypt::{hash, DEFAULT_COST};
use paperclip::actix::{
    api_v2_operation, post,
    web::{self, Json},
};
use validator::Validate;

use crate::{
    db::DB,
    middleware::jwt::make_jwt,
    models::{shared::UuidModel, user::User},
    routes::common::Jwt,
};

fn hash_password(password: &str) -> Result<String, bcrypt::BcryptError> {
    hash(password, DEFAULT_COST)
}

#[api_v2_operation]
#[post("/signup")]
async fn signup(db: web::Data<Mutex<DB>>, body: Json<User>) -> Result<Json<Jwt>, Error> {
    let mut db = db.lock().unwrap();
    let user = body.into_inner();
    let hashed_password = hash_password(&user.password)
        .map_err(|_| actix_web::error::ErrorInternalServerError("Failed to hash password"))?;
    let user = User {
        uuid: UuidModel::new(),
        password: hashed_password,
        ..user
    };

    let user_exists = db.user_with_username_exists(&user.username).map_err(|_| {
        actix_web::error::ErrorInternalServerError("Failed to check username availability")
    })?;

    if user_exists {
        return Err(actix_web::error::ErrorBadRequest("Username already taken"));
    }

    user.validate()
        .map_err(|e| actix_web::error::ErrorBadRequest(e))?;

    db.insert_user(&user).map_err(|_| {
        actix_web::error::ErrorInternalServerError("Failed to insert user into database")
    })?;

    make_jwt(&user.uuid)
        .map(|jwt| Json(Jwt { jwt }))
        .map_err(|_| actix_web::error::ErrorInternalServerError("Failed to create JWT"))
}
