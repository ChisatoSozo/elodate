// use async_mutex::Mutex;

// use actix_web::{Error, HttpMessage, HttpRequest};

// use paperclip::actix::{
//     api_v2_operation, post,
//     web::{self, Json},
// };

// use crate::{
//     db::DB,
//     internal_models::{chat::Chat, shared::UuidModel},
// };

// #[api_v2_operation]
// #[post("/get_my_chats")]
// pub async fn get_my_chats(
//     db: web::Data<Mutex<DB>>,
//     req: HttpRequest,
// ) -> Result<Json<Vec<Chat>>, Error> {
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

//     let chats = user.get_chats(&mut db).map_err(|e| {
//         println!("Failed to get chats {:?}", e);
//         actix_web::error::ErrorInternalServerError("Failed to get chats")
//     })?;

//     Ok(Json(chats))
// }
