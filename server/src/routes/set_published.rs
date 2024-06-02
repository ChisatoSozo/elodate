use actix_web::Error;

use paperclip::actix::{
    api_v2_operation, post,
    web::{self, Json},
};

use crate::{db::DB, models::internal_models::shared::Save, routes::shared::route_body_mut_db};

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
            let publishable_msg = user.publishable_msg();
            if publishable_msg != "" {
                return Err(actix_web::error::ErrorBadRequest(
                    publishable_msg.to_string(),
                ));
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
