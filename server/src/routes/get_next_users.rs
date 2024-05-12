use std::sync::Mutex;

use actix_web::{Error, HttpMessage, HttpRequest};

use paperclip::actix::{
    api_v2_operation, post,
    web::{self, Json},
};

use crate::{
    db::DB,
    models::{shared::UuidModel, user::UserWithImagesAndElo},
    procedures::get_user_set::get_user_set,
};

#[api_v2_operation]
#[post("/get_next_users")]
pub async fn get_next_users(
    db: web::Data<Mutex<DB>>,
    req: HttpRequest,
    rate: web::Json<Vec<UuidModel>>,
) -> Result<Json<Vec<UserWithImagesAndElo>>, Error> {
    let ext = req.extensions();
    let user = ext.get::<UuidModel>().unwrap();
    let mut db = db.lock().unwrap();
    let skip = rate.into_inner();
    let user_set = get_user_set(&mut db, &user, skip).await?;
    Ok(Json(user_set))
}
