use std::sync::Mutex;

use actix_cors::Cors;
use actix_web::{App, HttpServer};

use db::DB;
use middleware::jwt::Jwt;
use paperclip::actix::{web, OpenApiExt};

use routes::{
    check_username::check_username, generate_access_codes::generate_access_codes,
    get_chat_messages::get_chat_messages, get_me::get_me, get_my_chats::get_my_chats,
    get_next_users::get_next_users, get_user_with_single_image::get_user_with_single_image,
    login::login, signup::signup, update_user::update_user,
};

pub mod constants;
pub mod db;
pub mod elo;
pub mod middleware;
pub mod models;
pub mod mokuroku;
pub mod procedures;
pub mod routes;
pub mod test;
pub mod util;

const JSON_SPEC_PATH: &str = "/api/spec/v2.json";

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    let db = web::Data::new(Mutex::new(DB::new("test")));

    HttpServer::new(move || {
        App::new()
            .wrap(Cors::permissive())
            .app_data(db.clone())
            .wrap_api()
            .wrap(Jwt)
            .service(signup)
            .service(login)
            .service(generate_access_codes)
            .service(check_username)
            .service(get_next_users)
            .service(update_user)
            .service(get_my_chats)
            .service(get_chat_messages)
            .service(get_user_with_single_image)
            .service(get_me)
            .with_json_spec_at(JSON_SPEC_PATH)
            .build()
    })
    .bind(("127.0.0.1", 8080))?
    .run()
    .await
}
