

use actix_web::{Error, HttpRequest};

use paperclip::actix::{
    api_v2_operation, post,
    web::{self, Json},
};

use crate::{db::DB, models::api_models::api_user::ApiUser, routes::shared::route_body_mut_db};

#[api_v2_operation]
#[post("/get_users_mutual_perfer_count_dry_run")]
pub fn get_users_mutual_perfer_count_dry_run(
    db: web::Data<DB>,
    req: HttpRequest,
    body: Json<ApiUser>,
) -> Result<Json<usize>, Error> {
    route_body_mut_db(db, req, body, |db, user, body| {
        let users_mutual_perfer_count = db.get_mutual_preference_users_count_direct(
            &body.properties,
            &body.preferences,
            &user.seen,
        );
        Ok(users_mutual_perfer_count)
    })
    
}
