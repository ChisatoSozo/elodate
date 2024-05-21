

use actix_web::{Error, HttpRequest};

use paperclip::actix::{
    api_v2_operation, post,
    web::{self, Json},
};

use crate::{
    db::DB, models::api_models::api_user::ApiUserWritable, routes::shared::route_body_mut_db,
};

use crate::models::internal_models::shared::Save;

#[api_v2_operation]
#[post("/put_user")]
async fn put_user(
    db: web::Data<DB>,
    req: HttpRequest,
    body: Json<ApiUserWritable>,
) -> Result<Json<bool>, Error> {
    route_body_mut_db(db, req, body, |db, user, new_user| {
        //are they writing themselves
        if new_user.uuid != user.uuid.into() {
            return Err(actix_web::error::ErrorBadRequest(
                "You can't write other users",
            ));
        }

        //did they choose a new username, and it already exists
        if new_user.username != user.username {
            let user_with_username = db.get_user_by_username(&new_user.username).map_err(|e| {
                println!("Failed to get user by username {:?}", e);
                actix_web::error::ErrorInternalServerError("Failed to get user by username")
            })?;
            if user_with_username.is_some() {
                return Err(actix_web::error::ErrorBadRequest("Username already exists"));
            }
        }

        let new_user_internal = new_user.to_internal(db)?;
        new_user_internal.save(db).map_err(|e| {
            println!("Failed to save user {:?}", e);
            actix_web::error::ErrorInternalServerError("Failed to save user")
        })?;

        Ok(true)
    })
    
}
