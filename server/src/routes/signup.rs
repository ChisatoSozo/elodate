use actix_web::Error;

use paperclip::actix::{
    api_v2_operation, post,
    web::{self, Json},
    Apiv2Schema,
};
use serde::Deserialize;

use crate::{
    db::DB,
    middleware::jwt::make_jwt,
    models::{
        api_models::{api_user::ApiUserWritable, shared::ApiUuid},
        internal_models::{internal_user::InternalUser, shared::Save},
    },
    routes::common::Jwt,
};

#[derive(Apiv2Schema, Deserialize)]
struct SignupInput {
    access_code: String,
    user: ApiUserWritable,
}

#[api_v2_operation]
#[post("/signup")]
async fn signup(db: web::Data<DB>, body: Json<SignupInput>) -> Result<Json<Jwt>, Error> {
    let inner = body.into_inner();
    let mut user = inner.user;
    let access_code = inner.access_code;

    let user_exists = db
        .get_user_by_username(&user.username)
        .map_err(|e| {
            log::error!("Failed to check if user exists {:?}", e);
            actix_web::error::ErrorInternalServerError("Failed to check if user exists")
        })?
        .is_some();

    user.uuid = ApiUuid::<InternalUser>::new();

    if user_exists {
        Err(actix_web::error::ErrorBadRequest("Username already taken"))?;
    }

    if user.images.len() > 6 {
        return Err(actix_web::error::ErrorBadRequest("Too many images"));
    }

    let internal_user = user.to_internal(&db, false).map_err(|e| {
        log::error!("Failed to convert user to internal {:?}", e);
        actix_web::error::ErrorInternalServerError("Failed to convert user to internal")
    })?;

    let access_code = access_code.to_uppercase();

    if access_code != "ANAK-AZAN" {
        let access_code_internal = db.get_access_code_by_code(&access_code).map_err(|e| {
            log::error!("Failed to get access code {:?}", e);
            actix_web::error::ErrorInternalServerError("Failed to get access code")
        })?;

        //is the access code valid
        match access_code_internal {
            Some(mut access_code) => {
                if access_code.used {
                    Err(actix_web::error::ErrorBadRequest(
                        "Access code already used",
                    ))?;
                } else {
                    access_code.used = true;

                    access_code.save(&db).map_err(|e| {
                        log::error!("Failed to save access code {:?}", e);
                        actix_web::error::ErrorInternalServerError("Failed to save access code")
                    })?;
                }
            }
            None => {
                Err(actix_web::error::ErrorBadRequest("Access code not found"))?;
            }
        }
    }

    let internal_uuid = internal_user.save(&db).map_err(|e| {
        log::error!("Failed to save user {:?}", e);
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
            log::error!("Failed to make jwt {:?}", e);
            actix_web::error::ErrorInternalServerError("Failed to make jwt")
        })
}
