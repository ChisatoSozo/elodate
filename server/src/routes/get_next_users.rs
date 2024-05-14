use async_mutex::Mutex;

use actix_web::{Error, HttpMessage, HttpRequest};

use paperclip::actix::{
    api_v2_operation, post,
    web::{self, Json},
};

use crate::{
    db::DB,
    models::{shared::UuidModel, user::UserWithImagesAndEloAndUuid},
    procedures::get_user_set::get_user_set,
};

#[api_v2_operation]
#[post("/get_next_users")]
pub async fn get_next_users(
    db: web::Data<Mutex<DB>>,
    req: HttpRequest,
    body: web::Json<Vec<UuidModel>>,
) -> Result<Json<Vec<UserWithImagesAndEloAndUuid>>, Error> {
    let ext = req.extensions();
    let user = ext.get::<UuidModel>().unwrap();
    let mut db = db.lock().await;
    let skip = body.into_inner();
    let user_set = get_user_set(&mut db, &user, skip).await?;
    Ok(Json(user_set))
}
