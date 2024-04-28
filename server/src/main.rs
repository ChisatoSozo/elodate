use std::sync::Mutex;

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

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    let db = web::Data::new(Mutex::new(DB::new("prod")));

    HttpServer::new(move || {
        App::new()
            .app_data(db.clone())
            .wrap_api()
            .wrap(Jwt)
            .service(signup)
            .service(generate_access_codes)
            .service(check_username)
            .with_json_spec_at("/api/spec/v2.json")
            .build()
    })
    .bind(("127.0.0.1", 8080))?
    .run()
    .await
}
