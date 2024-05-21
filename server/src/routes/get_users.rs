use actix_web::Error;

use paperclip::actix::{
    api_v2_operation, post,
    web::{self, Json},
};

use crate::{
    db::DB,
    models::{
        api_models::{api_user::ApiUser, shared::ApiUuid},
        internal_models::{internal_user::InternalUser, shared::InternalUuid},
    },
    routes::shared::route_body_mut_db,
};

#[api_v2_operation]
#[post("/get_users")]
pub fn get_users(
    db: web::Data<DB>,
    req: web::HttpRequest,
    body: Json<Vec<ApiUuid<InternalUser>>>,
) -> Result<Json<Vec<ApiUser>>, Error> {
    route_body_mut_db(db, req, body, |db, user, body| {
        let users = body
            .into_iter()
            .map(|user_uuid| {
                let internal_uuid: InternalUuid<_> = user_uuid.into();
                internal_uuid
                    .load(db)
                    .map_err(|e| {
                        println!("Failed to get user by uuid {:?}", e);
                        actix_web::error::ErrorInternalServerError("Failed to get user by uuid")
                    })
                    .and_then(|user| {
                        user.ok_or_else(|| actix_web::error::ErrorNotFound("User not found"))
                    })
            })
            .collect::<Result<Vec<_>, _>>()?;

        let api_users: Vec<ApiUser> = users
            .into_iter()
            .map(|internal_user| ApiUser::from_internal(internal_user, &user))
            .collect::<Result<Vec<_>, _>>()?;
        Ok(api_users)
    })
}
