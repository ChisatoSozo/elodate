use std::sync::Mutex;

use actix_web::Error;

use paperclip::actix::{
    api_v2_operation, post,
    web::{self, Json},
    Apiv2Schema,
};
use serde::{Deserialize, Serialize};

use crate::{
    db::DB,
    middleware::jwt::make_jwt,
    models::{image::Image, user::User},
    procedures::upsert_user::upsert_user,
    routes::common::Jwt,
};

#[derive(Debug, Serialize, Deserialize, Apiv2Schema, Clone, PartialEq, Eq)]
struct SignupInput {
    user: User,
    images: Vec<Image>,
}

#[api_v2_operation]
#[post("/signup")]
async fn signup(db: web::Data<Mutex<DB>>, body: Json<SignupInput>) -> Result<Json<Jwt>, Error> {
    let mut db = db.lock().unwrap();
    let inner = body.into_inner();
    let user = inner.user;
    let images = inner.images;

    upsert_user(&user, images, &mut db).await?;

    make_jwt(&user.uuid)
        .map(|jwt| Json(Jwt { jwt }))
        .map_err(|e| {
            println!("Failed to make jwt {:?}", e);
            actix_web::error::ErrorInternalServerError("Failed to make jwt")
        })
}
