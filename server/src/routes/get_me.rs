use actix_web::Error;

use paperclip::actix::{
    api_v2_operation, post,
    web::{self, Json},
};

use crate::{db::DB, models::api_models::api_user::ApiUser, routes::shared::route_body_mut_db};

#[api_v2_operation]
#[post("/get_me")]
pub fn get_me(
    db: web::Data<DB>,
    req: web::HttpRequest,
    body: Json<bool>,
) -> Result<Json<ApiUser>, Error> {
    route_body_mut_db(db, req, body, |_, user, _| {
        ApiUser::from_internal(user, None).map_err(|e| {
            log::error!("Failed to get me {:?}", e);
            actix_web::error::ErrorInternalServerError("Failed to get me")
        })
    })
}
