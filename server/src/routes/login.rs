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
async fn login(db: web::Data<DB>, body: Json<LoginRequest>) -> Result<Json<Jwt>, Error> {
    let login_req = body.into_inner();
    let user = db.get_user_by_username(&login_req.username).map_err(|e| {
        println!("Failed to get user by username {:?}", e);
        actix_web::error::ErrorInternalServerError("Failed to get user by username")
    })?;
    let user = match user {
        Some(user) => user,
        None => return Err(actix_web::error::ErrorNotFound("User not found")),
    };
    let hashed_password = user.hashed_password.clone();
    let password_matches = verify_password(&login_req.password, &hashed_password).map_err(|e| {
        println!("Failed to verify password {:?}", e);
        actix_web::error::ErrorInternalServerError("Failed to verify password")
    })?;
    if !password_matches {
        return Err(actix_web::error::ErrorBadRequest("Incorrect password"));
    }

    make_jwt(&user.uuid)
        .map(|jwt| {
            Json(Jwt {
                jwt,
                uuid: user.uuid.into(),
            })
        })
        .map_err(|e| {
            println!("Failed to make jwt {:?}", e);
            actix_web::error::ErrorInternalServerError("Failed to make jwt")
        })
}
