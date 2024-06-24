use std::{array, sync::Arc, thread};

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
    check_username::check_username, fetch_notifications::fetch_notifications, get_chats::get_chats,
    get_images::get_images, get_me::get_me, get_message::get_message, get_messages::get_messages,
    get_next_users::get_next_users, get_prefs_config::get_prefs_config, get_users::get_users,
    get_users_i_perfer_count_dry_run::get_users_i_perfer_count_dry_run,
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
const BOT_ACTION_DELAY: u64 = 1;
const TASK_DELAY: u64 = 600;
const NUM_BOT_THREADS: usize = 10;

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    //fetch host and port environment variables
    let host = std::env::var("HOST").unwrap_or_else(|_| "localhost".to_string());

    let prod = std::env::var("PROD").is_ok();
    if !prod {
        println!("Running in dev mode, bots will be enabled");
    }

    let db_name = if prod { "prod" } else { "dummy" };

    let db = web::Data::new(DB::new(db_name).map_err(|e| {
        println!("Failed to create db {:?}", e);
        std::io::Error::new(std::io::ErrorKind::Other, "Failed to create db")
    })?);

    // spawn a thread that executes run_all_tasks then waits 10 minutes and repeats
    let db_clone = db.clone();
    std::thread::spawn(move || loop {
        run_all_tasks(&db_clone).unwrap();
        std::thread::sleep(std::time::Duration::from_secs(TASK_DELAY));
    });
    // if !prod {
    //     let db_clone = db.clone();
    //     let host = host.clone();

    //     std::thread::spawn(move || {
    //         println!("Waiting 1 seconds before starting bots");
    //         std::thread::sleep(std::time::Duration::from_secs(1));
    //         let uuid_jwt = init_bots(&db_clone, &host).unwrap();
    //         let clients: [Arc<reqwest::blocking::Client>; NUM_BOT_THREADS] =
    //             array::from_fn(|_| Arc::new(reqwest::blocking::Client::new()));
    //         loop {
    //             println!("Running bots");
    //             let num_threads = 10;
    //             let total = uuid_jwt.len();
    //             let mut handles = vec![];

    //             for i in 0..num_threads {
    //                 let db_clone = db_clone.clone();
    //                 let uuid_jwt = uuid_jwt.clone();
    //                 let client_clone = clients[i].clone();
    //                 let host = host.clone();
    //                 let handle = thread::spawn(move || {
    //                     let start = (i * total) / num_threads;
    //                     let mut end = ((i + 1) * total) / num_threads;
    //                     if end > uuid_jwt.len() {
    //                         end = uuid_jwt.len();
    //                     }

    //                     for ix in start..end {
    //                         let uuid_jwt = &uuid_jwt[ix];
    //                         let res =
    //                             run_all_bot_actions(&client_clone, &db_clone, uuid_jwt, &host);
    //                         std::thread::sleep(std::time::Duration::from_secs(BOT_ACTION_DELAY));
    //                         match res {
    //                             Ok(_) => {
    //                                 continue;
    //                             }
    //                             Err(e) => {
    //                                 println!("Bot failed to run {:?}", e);
    //                             }
    //                         }
    //                     }
    //                 });
    //                 handles.push(handle);
    //             }

    //             // Wait for all threads to complete
    //             for handle in handles {
    //                 handle.join().unwrap();
    //             }
    //         }
    //     });
    // }

    println!("Starting server at http://{}:8080", &host);

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
            .service(get_message)
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
            .service(fetch_notifications)
            .build()
    })
    .workers(4)
    .client_request_timeout(std::time::Duration::from_secs(600)) // Set client timeout to 10 minutes
    .client_disconnect_timeout(std::time::Duration::from_secs(600)) // Set client disconnect timeout to 10 minutes
    .bind((host, 8080))?
    .run()
    .await
}
