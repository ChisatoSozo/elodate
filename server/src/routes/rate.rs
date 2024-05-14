use async_mutex::Mutex;

use actix_web::{Error, HttpMessage, HttpRequest};

use paperclip::actix::{
    api_v2_operation, post,
    web::{self, Json},
};

use crate::{
    db::DB,
    models::{rating::RatingWithTarget, shared::UuidModel, success::Success},
    procedures::add_rating::add_rating,
};

#[api_v2_operation]
#[post("/rate")]
pub async fn rate(
    db: web::Data<Mutex<DB>>,
    req: HttpRequest,
    rate: web::Json<RatingWithTarget>,
) -> Result<Json<Success>, Error> {
    let db_inner = db.into_inner();
    let mut db = db_inner.lock().await;
    let ext = req.extensions();
    let source = ext.get::<UuidModel>().unwrap();
    let rating_with_target = rate.into_inner();
    let rating = rating_with_target.rating;
    let target = rating_with_target.target;

    add_rating(rating, source.clone(), target, &mut db).await?;
    Ok(Json(Success("Rating added".to_string())))
}
