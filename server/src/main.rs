use std::sync::Mutex;

use actix_web::{App, Error, HttpServer};
use bcrypt::{hash, verify, DEFAULT_COST};
use db::DB;
use paperclip::actix::{
    api_v2_operation, get, post,
    web::{self, Json},
    OpenApiExt,
};

use models::user::User;

pub mod db;
pub mod elo;
pub mod models;
pub mod mokuroku;

fn hash_password(password: &str) -> Result<String, bcrypt::BcryptError> {
    hash(password, DEFAULT_COST)
}

fn verify_password(password: &str, hash: &str) -> Result<bool, bcrypt::BcryptError> {
    verify(password, hash)
}

#[api_v2_operation]
#[post("/signup")]
async fn signup(body: Json<User>) -> Result<Json<User>, Error> {
    let user = body.into_inner();
    let hashed_password = hash_password(&user.password)
        .map_err(|e| actix_web::error::ErrorInternalServerError("Failed to hash password"))?;
    let user = User {
        password: hashed_password,
        ..user
    };

    Ok(Json(user))
}

#[api_v2_operation]
#[get("/asdf")]
async fn asdf(db: web::Data<Mutex<DB>>) -> Result<String, Error> {
    let mut db = db.lock().unwrap();
    let generated = db.get_flag("access_codes_generated");

    if generated {
        return Ok("Access codes already generated".to_string());
    }

    let access_codes = (0..10000)
        .map(|_| models::access_code::AccessCode::random_access_code())
        .collect::<Vec<_>>();

    //write access_codes to access_codes.txt
    let access_codes_str = access_codes
        .iter()
        .map(|access_code| {
            format!(
                "{}\t{}\t{}\n",
                access_code.uuid, access_code.code, access_code.used
            )
        })
        .collect::<String>();

    std::fs::write("access_codes.txt", access_codes_str).unwrap();

    db.set_flag("access_codes_generated", true);

    Ok("Access codes generated".to_string())
}

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    let db = web::Data::new(Mutex::new(DB::new("prod")));

    HttpServer::new(move || {
        App::new()
            .app_data(db.clone())
            .wrap_api()
            .service(signup)
            .service(asdf)
            .with_json_spec_at("/api/spec/v2")
            .build()
    })
    .bind(("127.0.0.1", 8080))?
    .run()
    .await
}
