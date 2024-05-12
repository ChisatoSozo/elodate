use std::sync::Mutex;

use actix_web::{Error, HttpMessage, HttpRequest};

use paperclip::actix::{
    api_v2_operation, post,
    web::{self, Json},
};

use crate::{
    db::DB,
    models::{
        shared::UuidModel,
        success::Success,
        user::{User, UserWithImages},
    },
    procedures::upsert_user::upsert_user,
};

#[api_v2_operation]
#[post("/update_user")]
async fn update_user(
    db: web::Data<Mutex<DB>>,
    req: HttpRequest,
    body: Json<UserWithImages>,
) -> Result<Json<Success>, Error> {
    let ext = req.extensions();
    let uuid = ext.get::<UuidModel>().unwrap();
    let mut db = db.lock().unwrap();
    let inner = body.into_inner();

    let user = inner.user;
    let images = inner.images;

    let old_user = db.get_user_by_uuid(&uuid).map_err(|e| {
        println!("Failed to get user {:?}", e);
        actix_web::error::ErrorInternalServerError("Failed to get user")
    })?;

    let user_with_uuid = User {
        public: user,
        ..old_user
    };

    let user_exists = db
        .user_with_username_exists(&user_with_uuid.public.username)
        .map_err(|e| {
            println!("Failed to check if user exists {:?}", e);
            actix_web::error::ErrorInternalServerError("Failed to check if user exists")
        })?;

    if user_exists {
        Err(actix_web::error::ErrorBadRequest("Username already taken"))?;
    }

    upsert_user(&user_with_uuid, images, &mut db).await?;

    Ok(Json(Success("User updated".to_string())))
}
