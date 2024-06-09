use actix_cors::Cors;
use actix_files::Files;
use actix_web::{
    guard,
    http::{header, Method},
    App, HttpServer,
};

use db::DB;
use middleware::jwt::Jwt;

use paperclip::actix::{web, OpenApiExt};

use routes::{
    check_username::check_username, get_chats::get_chats, get_images::get_images, get_me::get_me,
    get_messages::get_messages, get_next_users::get_next_users, get_prefs_config::get_prefs_config,
    get_users::get_users, get_users_i_perfer_count_dry_run::get_users_i_perfer_count_dry_run,
    get_users_mutual_perfer_count_dry_run::get_users_mutual_perfer_count_dry_run, login::login,
    put_image::put_image, put_user::put_user, rate::rate, report_bug::report_bug,
    send_message::send_message, set_published::set_published, signup::signup,
};
use tasks::tasks::run_all_tasks;

pub mod constants;
pub mod db;
pub mod elo;
pub mod middleware;
pub mod models;
pub mod routes;
pub mod tasks;
pub mod test;
pub mod util;
pub mod vec;

const JSON_SPEC_PATH: &str = "/api/spec/v2.json";

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    let db = web::Data::new(DB::new("dummy").map_err(|e| {
        println!("Failed to create db {:?}", e);
        std::io::Error::new(std::io::ErrorKind::Other, "Failed to create db")
    })?);

    // spawn a thread that executes run_all_tasks then waits 10 minutes and repeats
    let db_clone = db.clone();
    std::thread::spawn(move || loop {
        run_all_tasks(&db_clone).unwrap();
        std::thread::sleep(std::time::Duration::from_secs(600));
    });

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
            .service(
                Files::new("/", "./public")
                    .index_file("index.html")
                    //serve only get requests that are not JSON_SPEC_PATH
                    .guard(guard::fn_guard(|req| {
                        req.head().method == Method::GET && req.head().uri.path() != JSON_SPEC_PATH
                    })),
            )
            .wrap_api()
            .with_json_spec_at(JSON_SPEC_PATH)
            .wrap(Jwt)
            .service(signup)
            .service(login)
            .service(get_users)
            .service(get_chats)
            .service(get_messages)
            .service(check_username)
            .service(send_message)
            .service(get_prefs_config)
            .service(put_user)
            .service(get_me)
            .service(get_users_i_perfer_count_dry_run)
            .service(get_users_mutual_perfer_count_dry_run)
            .service(get_next_users)
            .service(get_images)
            .service(put_image)
            .service(set_published)
            .service(rate)
            .service(report_bug)
            .build()
    })
    .bind(("localhost", 8080))?
    .run()
    .await
}
