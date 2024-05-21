// use actix_web::Error;
// use actix_web::HttpMessage;

// use async_mutex::Mutex;
// use paperclip::actix::{
//     api_v2_operation, post,
//     web::{self, Json},
// };

// use crate::internal_models::user::UserWithImagesAndEloAndUuid;
// use crate::{db::DB, elo::elo_to_label, internal_models::shared::UuidModel};

// #[api_v2_operation]
// #[post("/get_me")]
// pub async fn get_me(
//     db: web::Data<Mutex<DB>>,
//     req: web::HttpRequest,
// ) -> Result<Json<UserWithImagesAndEloAndUuid>, Error> {
//     let ext = req.extensions();
//     let user_uuid = ext.get::<UuidModel>().unwrap();
//     let mut db = db.lock().await;
//     let user = db.get_user(&user_uuid).map_err(|e| {
//         println!("Failed to get user by uuid {:?}", e);
//         actix_web::error::ErrorInternalServerError("Failed to get user by uuid")
//     })?;
//     let user = match user {
//         Some(user) => user,
//         None => return Err(actix_web::error::ErrorNotFound("User not found")),
//     };

//     let images = db.get_images_from_user(&user.uuid).map_err(|e| {
//         println!("Failed to get image from user {:?}", e);
//         actix_web::error::ErrorInternalServerError("Failed to get images from user")
//     })?;

//     let user_with_images = UserWithImagesAndEloAndUuid {
//         user: user.public,
//         images,
//         elo: elo_to_label(user.elo),
//         uuid: user.uuid,
//     };

//     Ok(Json(user_with_images))
// }
