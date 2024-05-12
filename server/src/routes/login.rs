use std::sync::Mutex;

use actix_web::Error;
use bcrypt::verify;
use paperclip::actix::{
    api_v2_operation, post,
    web::{self, Json},
    Apiv2Schema,
};
use serde::{Deserialize, Serialize};

use crate::{db::DB, middleware::jwt::make_jwt, routes::common::Jwt};

fn verify_password(password: &str, hash: &str) -> Result<bool, bcrypt::BcryptError> {
    verify(password, hash)
}

#[derive(Debug, Serialize, Deserialize, Apiv2Schema, Clone, PartialEq, Eq)]
pub struct LoginRequest {
    pub username: String,
    pub password: String,
}

#[api_v2_operation]
#[post("/login")]
async fn login(db: web::Data<Mutex<DB>>, body: Json<LoginRequest>) -> Result<Json<Jwt>, Error> {
    let mut db = db.lock().unwrap();
    let user = body.into_inner();
    let user = db.get_user_by_username(&user.username).map_err(|e| {
        println!("Failed to get user by username {:?}", e);
        actix_web::error::ErrorInternalServerError("Failed to get user by username")
    })?;
    let hashed_password = user.password.clone();
    let password_matches = verify_password(&user.password, &hashed_password).map_err(|e| {
        println!("Failed to verify password {:?}", e);
        actix_web::error::ErrorInternalServerError("Failed to verify password")
    })?;
    if !password_matches {
        return Err(actix_web::error::ErrorBadRequest("Invalid password"));
    }

    make_jwt(&user.uuid)
        .map(|jwt| Json(Jwt { jwt }))
        .map_err(|e| {
            println!("Failed to make jwt {:?}", e);
            actix_web::error::ErrorInternalServerError("Failed to make jwt")
        })
}
