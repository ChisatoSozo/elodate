use actix_web::Error;

use paperclip::actix::{
    api_v2_operation, post,
    web::{self, Json},
};

use crate::{
    db::DB,
    models::internal_models::{internal_prefs::PREFS_CONFIG, shared::Save},
    routes::shared::route_body_mut_db,
};

#[api_v2_operation]
#[post("/set_published")]
pub fn set_published(
    db: web::Data<DB>,
    req: web::HttpRequest,
    body: Json<bool>,
) -> Result<Json<bool>, Error> {
    route_body_mut_db(db, req, body, |db, mut user, body| {
        let published = body;
        if published {
            if user.images.len() < 1 {
                return Err(actix_web::error::ErrorBadRequest(
                    "You must have at least one image",
                ));
            }
            let mandatory_props = PREFS_CONFIG
                .iter()
                .filter(|p| !p.optional)
                .map(|p| p.name)
                .collect::<Vec<_>>();

            for prop in mandatory_props {
                if !user.props.iter().any(|p| p.name == prop) {
                    return Err(actix_web::error::ErrorBadRequest(format!(
                        "You must have the property {}",
                        prop
                    )));
                }
            }
        }

        user.published = body;
        user.save(db).map_err(|e| {
            println!("Failed to save user {:?}", e);
            actix_web::error::ErrorInternalServerError("Failed to save user")
        })?;

        Ok(true)
    })
}
