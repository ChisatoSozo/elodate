use std::sync::{
    atomic::{AtomicUsize, Ordering},
    Arc,
};

use actix_cors::Cors;
use actix_files::Files;
use actix_web::{
    guard,
    http::{header, Method},
    App, HttpServer,
};

use bots::bot_actions::{init_bots, run_all_bot_actions};
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

pub mod bots;
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
    //fetch host and port environment variables
    let host = std::env::var("HOST").unwrap_or_else(|_| "localhost".to_string());

    let prod = std::env::var("PROD").is_ok();
    if !prod {
        println!("Running in dev mode, bots will be enabled");
    }

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
    if !prod {
        let db_clone = db.clone();

        std::thread::spawn(move || {
            println!("Waiting 1 seconds before starting bots");
            std::thread::sleep(std::time::Duration::from_secs(1));
            let uuid_jwt = init_bots(&db_clone).unwrap();
            loop {
                println!("Running bots");
                let batch_num = 10;
                let total = uuid_jwt.len();
                let ix = Arc::new(AtomicUsize::new(0));
                //spin off 10 threads to run each of 10 sections of the bots
                for i in 0..uuid_jwt.len() / batch_num {
                    let db_clone = db_clone.clone();
                    let uuid_jwt = uuid_jwt.clone();
                    let ix = Arc::clone(&ix);
                    std::thread::spawn(move || {
                        let start = i * batch_num;
                        let end = (i + 1) * batch_num;
                        for uuid_jwt in &uuid_jwt[start..end] {
                            let current_ix = ix.fetch_add(1, Ordering::SeqCst);
                            if current_ix % 10 == 0 {
                                println!("Running bot {}/{}", current_ix, total);
                            }

                            run_all_bot_actions(&db_clone, uuid_jwt).unwrap();
                        }
                    });
                }

                // std::thread::sleep(std::time::Duration::from_secs(10));
            }
        });
    }

    println!("Starting server at http://{}:8080", host);

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
