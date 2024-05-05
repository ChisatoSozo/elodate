use std::sync::Mutex;

use actix_cors::Cors;
use actix_web::{App, HttpServer};

use db::DB;
use middleware::jwt::Jwt;
use paperclip::actix::{web, OpenApiExt};

use routes::{
    check_username::check_username, generate_access_codes::generate_access_codes, signup::signup,
};

pub mod db;
pub mod elo;
pub mod middleware;
pub mod models;
pub mod mokuroku;
pub mod routes;

const JSON_SPEC_PATH: &str = "/api/spec/v2.json";

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    let db = web::Data::new(Mutex::new(DB::new("prod")));

    HttpServer::new(move || {
        App::new()
            .wrap(Cors::permissive())
            .app_data(db.clone())
            .wrap_api()
            .wrap(Jwt)
            .service(signup)
            .service(generate_access_codes)
            .service(check_username)
            .with_json_spec_at(JSON_SPEC_PATH)
            .build()
    })
    .bind(("127.0.0.1", 8080))?
    .run()
    .await
}
