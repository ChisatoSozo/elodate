

use actix_web::Error;

use paperclip::actix::{
    api_v2_operation, post,
    web::{self, Json},
};

use crate::{
    db::DB,
    models::internal_models::internal_preferences::{preferences_config, PreferencesConfig},
    routes::shared::route_body_mut_db,
};

#[api_v2_operation]
#[post("/get_preferences_config")]
pub fn get_preferences_config(
    db: web::Data<DB>,
    req: web::HttpRequest,
    body: Json<bool>,
) -> Result<Json<PreferencesConfig<'static>>, Error> {
    route_body_mut_db(db, req, body, |_, _, _| Ok(preferences_config()))
}
