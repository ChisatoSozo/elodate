use actix_web::{App, Error, HttpServer};
use db::DB;
use paperclip::actix::{
    api_v2_operation, post,
    web::{self, Json},
    OpenApiExt,
};

use models::user::User;

pub mod db;
pub mod models;
pub mod mokuroku;

#[api_v2_operation]
#[post("/signup")]
async fn signup(body: Json<User>) -> Result<Json<User>, Error> {
    Ok(body)
}

// #[actix_web::post("/asdf")]
// async fn asdf() -> Result<String, Error> {
//     let access_codes = 0..10000
//         .map(|_| models::access_code::AccessCode::random_access_code())
//         .collect::<Vec<_>>();
// }

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    HttpServer::new(|| {
        App::new()
            .app_data(web::Data::new(DB::new("prod")))
            .wrap_api()
            .service(signup)
            .with_json_spec_at("/api/spec/v2")
            .build()
    })
    .bind(("127.0.0.1", 8080))?
    .run()
    .await
}
