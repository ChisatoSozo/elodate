use async_mutex::Mutex;

use actix_web::{Error, HttpMessage, HttpRequest};

use paperclip::actix::{
    api_v2_operation, post,
    web::{self, Json},
};

use crate::{
    db::DB,
    models::{preference, shared::UuidModel},
};

#[api_v2_operation]
#[post("/get_users_mutual_perfer_count_dry_run")]
pub async fn get_users_mutual_perfer_count_dry_run(
    db: web::Data<Mutex<DB>>,
    req: HttpRequest,
    body: Json<crate::models::preference::Preference>,
) -> Result<Json<usize>, Error> {
    let ext = req.extensions();
    let user_uuid = ext.get::<UuidModel>().unwrap();
    let preference = body.into_inner();
    let mut db = db.lock().await;
    let user = db.get_user_by_uuid(&user_uuid).map_err(|e| {
        println!("Failed to get user by uuid {:?}", e);
        actix_web::error::ErrorInternalServerError("Failed to get user by uuid")
    })?;

    let users_i_perfer_count =
        db.get_mutual_preference_users_count_direct(&user.public, &preference, &user.seen);

    Ok(Json(users_i_perfer_count))
}