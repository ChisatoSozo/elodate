use actix_cors::Cors;
use actix_web::{http::header, App, HttpServer};

use async_mutex::Mutex;
use db::DB;
use middleware::jwt::Jwt;
use paperclip::actix::{web, OpenApiExt};

use routes::{
    check_username::check_username, generate_access_codes::generate_access_codes,
    get_additional_preferences::get_additional_preferences, get_chat_messages::get_chat_messages,
    get_me::get_me, get_my_chats::get_my_chats, get_next_users::get_next_users,
    get_user_with_single_image::get_user_with_single_image,
    get_users_i_perfer_count::get_users_i_perfer_count,
    get_users_i_perfer_count_dry_run::get_users_i_perfer_count_dry_run,
    get_users_mutual_perfer_count::get_users_mutual_perfer_count,
    get_users_mutual_perfer_count_dry_run::get_users_mutual_perfer_count_dry_run, login::login,
    rate::rate, signup::signup, update_user::update_user,
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
pub mod vec;

const JSON_SPEC_PATH: &str = "/api/spec/v2.json";

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    let db = web::Data::new(Mutex::new(DB::new("test")));

    HttpServer::new(move || {
        App::new()
            .wrap(
                Cors::default()
                    .allow_any_origin()
                    .allowed_methods(vec!["GET", "POST"])
                    .allowed_headers(vec![header::AUTHORIZATION, header::ACCEPT])
                    .allowed_header(header::CONTENT_TYPE)
                    .max_age(3600),
            )
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
            .service(get_users_i_perfer_count)
            .service(get_users_i_perfer_count_dry_run)
            .service(get_users_mutual_perfer_count)
            .service(get_users_mutual_perfer_count_dry_run)
            .service(get_additional_preferences)
            .service(rate)
            .with_json_spec_at(JSON_SPEC_PATH)
            .build()
    })
    .bind(("127.0.0.1", 8080))?
    .run()
    .await
}
