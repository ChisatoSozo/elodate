use actix_web::Error;
use paperclip::actix::{
    api_v2_operation, post,
    web::{self, Json},
    Apiv2Schema,
};
use serde::{Deserialize, Serialize};

use crate::db::DB;

#[derive(Debug, Serialize, Deserialize, Apiv2Schema, Clone, PartialEq, Eq)]
struct CheckUsernameInput {
    username: String,
}

#[derive(Debug, Serialize, Deserialize, Apiv2Schema, Clone, PartialEq, Eq)]
struct CheckUsernameOutput {
    available: bool,
}

#[api_v2_operation]
#[post("/check_username")]
fn check_username(
    db: web::Data<DB>,
    body: Json<CheckUsernameInput>,
) -> Result<Json<CheckUsernameOutput>, Error> {
    let user = body.into_inner();

    let available = db
        .get_user_by_username(&user.username)
        .map_err(|e| {
            log::error!("Failed to check username availability: {:?}", e);
            actix_web::error::ErrorInternalServerError("Failed to check username availability")
        })?
        .is_none();
    return Ok(Json(CheckUsernameOutput { available }));
}
