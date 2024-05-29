use actix_web::Error;

use paperclip::actix::{
    api_v2_operation, post,
    web::{self, Json},
};

use crate::{
    db::DB,
    models::internal_models::internal_prefs::{PreferenceConfigPublic, PREFS_CONFIG},
    routes::shared::route_body_mut_db,
};

#[api_v2_operation]
#[post("/get_prefs_config")]
pub fn get_prefs_config(
    db: web::Data<DB>,
    req: web::HttpRequest,
    body: Json<bool>,
) -> Result<Json<Vec<PreferenceConfigPublic>>, Error> {
    route_body_mut_db(db, req, body, |_, _, _| {
        Ok(PREFS_CONFIG
            .iter()
            .cloned()
            .map(|p| p.get_public())
            .collect())
    })
}
