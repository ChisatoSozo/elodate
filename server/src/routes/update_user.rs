// use async_mutex::Mutex;

// use actix_web::{Error, HttpMessage, HttpRequest};

// use paperclip::actix::{
//     api_v2_operation, post,
//     web::{self, Json},
// };

// use crate::{
//     db::DB,
//     internal_models::{
//         shared::UuidModel,
//         success::Success,
//         user::{User, UserWithImages},
//     },
//     procedures::upsert_user::upsert_user,
// };

// #[api_v2_operation]
// #[post("/update_user")]
// async fn update_user(
//     db: web::Data<Mutex<DB>>,
//     req: HttpRequest,
//     body: Json<UserWithImages>,
// ) -> Result<Json<Success>, Error> {
//     let ext = req.extensions();
//     let uuid = ext.get::<UuidModel>().unwrap();
//     let mut db = db.lock().await;
//     let inner = body.into_inner();

//     let user = inner.user;
//     let images = inner.images;

//     let old_user = db.get_user(&uuid).map_err(|e| {
//         println!("Failed to get user {:?}", e);
//         actix_web::error::ErrorInternalServerError("Failed to get user")
//     })?;

//     let old_user = match old_user {
//         Some(user) => user,
//         None => return Err(actix_web::error::ErrorNotFound("User not found")),
//     };

//     let user_with_uuid = User {
//         public: user,
//         ..old_user
//     };

//     let user_exists = db
//         .get_user_by_username(&user_with_uuid.public.username)
//         .map_err(|e| {
//             println!("Failed to check if user exists {:?}", e);
//             actix_web::error::ErrorInternalServerError("Failed to check if user exists")
//         })?;

//     if user_exists.is_some() {
//         //is this the username this user already has?
//         let user_from_db = user_exists.unwrap();

//         if &user_from_db.public.username != &user_with_uuid.public.username {
//             return Err(actix_web::error::ErrorBadRequest("Username already exists"));
//         }
//     }

//     upsert_user(&user_with_uuid, images, &mut db)?;

//     Ok(Json(Success("User updated".to_string())))
// }
