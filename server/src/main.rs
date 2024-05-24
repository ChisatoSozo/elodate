use actix_cors::Cors;
use actix_web::{http::header, App, HttpServer};

use db::DB;
use middleware::jwt::Jwt;

use paperclip::actix::{web, OpenApiExt};

use routes::{
    check_username::check_username, get_chats::get_chats, get_images::get_images, get_me::get_me,
    get_messages::get_messages, get_next_users::get_next_users,
    get_preferences_config::get_preferences_config, get_users::get_users,
    get_users_i_perfer_count_dry_run::get_users_i_perfer_count_dry_run,
    get_users_mutual_perfer_count_dry_run::get_users_mutual_perfer_count_dry_run, login::login,
    put_user::put_user, rate::rate, send_message::send_message, signup::signup,
};

pub mod constants;
pub mod db;
pub mod elo;
pub mod middleware;
pub mod models;
pub mod routes;
pub mod test;
pub mod util;
pub mod vec;

const JSON_SPEC_PATH: &str = "/api/spec/v2.json";

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    let db = web::Data::new(DB::new("test").map_err(|e| {
        println!("Failed to create db {:?}", e);
        std::io::Error::new(std::io::ErrorKind::Other, "Failed to create db")
    })?);

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
            .service(get_users)
            .service(get_chats)
            .service(get_messages)
            .service(check_username)
            .service(send_message)
            .service(get_preferences_config)
            .service(put_user)
            .service(get_me)
            .service(get_users_i_perfer_count_dry_run)
            .service(get_users_mutual_perfer_count_dry_run)
            .service(get_next_users)
            .service(get_images)
            .service(rate)
            .with_json_spec_at(JSON_SPEC_PATH)
            .build()
    })
    .bind(("0.0.0.0", 8080))?
    .run()
    .await
}
