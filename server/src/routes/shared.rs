use actix_web::{
    web::{self, Json},
    HttpRequest,
};

use crate::{
    db::DB,
    models::internal_models::{internal_user::InternalUser, shared::InternalUuid},
};

use actix_web::HttpMessage;

pub fn route_body_mut_db<T, R>(
    db: web::Data<DB>,
    req: HttpRequest,
    body: Json<T>,
    fn_: impl FnOnce(&DB, InternalUser, T) -> Result<R, actix_web::Error>,
) -> Result<Json<R>, actix_web::Error> {
    let ext = req.extensions();
    let user_uuid = ext.get::<InternalUuid<InternalUser>>();
    let user_uuid = match user_uuid {
        Some(user_uuid) => user_uuid,
        None => return Err(actix_web::error::ErrorBadRequest("User not in session")),
    };

    let user = user_uuid.load(&db).map_err(|e| {
        println!("Failed to get user by uuid {:?}", e);
        actix_web::error::ErrorInternalServerError("Failed to get user by uuid")
    })?;

    let user = match user {
        Some(user) => user,
        None => return Err(actix_web::error::ErrorNotFound("User not found")),
    };

    let inner = body.into_inner();
    let result = fn_(&db, user, inner)?;
    Ok(Json(result))
}
