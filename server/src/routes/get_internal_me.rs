use actix_web::Error;

use paperclip::actix::{
    api_v2_operation, post,
    web::{self, Json},
};

use crate::{
    db::DB, models::internal_models::internal_user::InternalUser, routes::shared::route_body_mut_db,
};

#[api_v2_operation]
#[post("/get_internal_me")]
pub fn get_internal_me(
    db: web::Data<DB>,
    req: web::HttpRequest,
    body: Json<bool>,
) -> Result<Json<InternalUser>, Error> {
    route_body_mut_db(db, req, body, |_, user, _| Ok(user))
}
