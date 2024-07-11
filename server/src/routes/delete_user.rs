use actix_web::{Error, HttpRequest};

use paperclip::actix::{
    api_v2_operation, post,
    web::{self, Json},
};

use crate::{db::DB, routes::shared::route_body_mut_db};

#[api_v2_operation]
#[post("/delete_user")]
async fn delete_user(
    db: web::Data<DB>,
    req: HttpRequest,
    body: Json<bool>,
) -> Result<Json<bool>, Error> {
    route_body_mut_db(db, req, body, |db, user, _| {
        user.delete(db).map_err(|e| {
            log::error!("Failed to delete user {:?}", e);
            actix_web::error::ErrorInternalServerError("Failed to delete user")
        })?;
        db.flush().map_err(|e| {
            log::error!("Failed to flush db {:?}", e);
            actix_web::error::ErrorInternalServerError("Failed to flush db")
        })?;
        Ok(true)
    })
}
