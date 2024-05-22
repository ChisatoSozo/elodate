use actix_web::{Error, HttpRequest};

use paperclip::actix::{
    api_v2_operation, post,
    web::{self, Json},
};

use crate::{
    db::DB, models::internal_models::internal_preferences::Preferences,
    routes::shared::route_body_mut_db,
};

#[api_v2_operation]
#[post("/get_users_i_perfer_count_dry_run")]
pub fn get_users_i_perfer_count_dry_run(
    db: web::Data<DB>,
    req: HttpRequest,
    body: Json<Preferences>,
) -> Result<Json<usize>, Error> {
    route_body_mut_db(db, req, body, |db, user, body| {
        let users_i_perfer_count = db.get_users_i_prefer_count_direct(&body, &user.seen)?;
        Ok(users_i_perfer_count)
    })
}
