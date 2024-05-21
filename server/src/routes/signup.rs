use actix_web::Error;

use paperclip::actix::{
    api_v2_operation, post,
    web::{self, Json},
};

use crate::{
    db::DB,
    middleware::jwt::make_jwt,
    models::{
        api_models::{api_user::ApiUserWritable, shared::ApiUuid},
        internal_models::{internal_user::InternalUser, shared::Save},
    },
    routes::common::Jwt,
};

#[api_v2_operation]
#[post("/signup")]
async fn signup(db: web::Data<DB>, body: Json<ApiUserWritable>) -> Result<Json<Jwt>, Error> {
    let mut inner = body.into_inner();

    let user_exists = db
        .get_user_by_username(&inner.username)
        .map_err(|e| {
            println!("Failed to check if user exists {:?}", e);
            actix_web::error::ErrorInternalServerError("Failed to check if user exists")
        })?
        .is_some();

    inner.uuid = ApiUuid::<InternalUser>::new();

    if user_exists {
        Err(actix_web::error::ErrorBadRequest("Username already taken"))?;
    }

    let internal_user = inner.to_internal(&db).map_err(|e| {
        println!("Failed to convert user to internal {:?}", e);
        actix_web::error::ErrorInternalServerError("Failed to convert user to internal")
    })?;

    let internal_uuid = internal_user.save(&db).map_err(|e| {
        println!("Failed to save user {:?}", e);
        actix_web::error::ErrorInternalServerError("Failed to save user")
    })?;

    make_jwt(&internal_uuid)
        .map(|jwt| {
            Json(Jwt {
                jwt,
                uuid: internal_uuid.into(),
            })
        })
        .map_err(|e| {
            println!("Failed to make jwt {:?}", e);
            actix_web::error::ErrorInternalServerError("Failed to make jwt")
        })
}
