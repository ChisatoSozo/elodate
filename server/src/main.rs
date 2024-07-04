use std::sync::{
    atomic::{AtomicBool, Ordering},
    Arc,
};

use actix_cors::Cors;
use actix_files::Files;
use actix_web::{
    guard,
    http::{header, Method},
    App, HttpServer,
};

use bots::bot_manager::start_bot_manager;
use db::DB;
use logger::init_logs;
use middleware::jwt::Jwt;

use paperclip::actix::{web, OpenApiExt};

use routes::{
    check_username::check_username, fetch_notifications::fetch_notifications, get_chats::get_chats,
    get_images::get_images, get_me::get_me, get_message::get_message, get_messages::get_messages,
    get_next_users::get_next_users, get_prefs_config::get_prefs_config, get_users::get_users,
    get_users_i_perfer_count_dry_run::get_users_i_perfer_count_dry_run,
    get_users_mutual_perfer_count_dry_run::get_users_mutual_perfer_count_dry_run, login::login,
    put_image::put_image, put_user::put_user, rate::rate, report_bug::report_bug,
    send_message::send_message, signup::signup,
};
use tasks::tasks::run_all_tasks;

pub mod bots;
pub mod constants;
pub mod db;
pub mod elo;
pub mod logger;
pub mod middleware;
pub mod models;
pub mod routes;
pub mod tasks;
pub mod test;
pub mod util;
pub mod vec;

const JSON_SPEC_PATH: &str = "/api/spec/v2.json";
const TASK_DELAY: u64 = 600;

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    init_logs().unwrap();
    //fetch host and port environment variables
    let host = std::env::var("HOST").unwrap_or_else(|_| "localhost".to_string());
    let enable_bots = std::env::var("ENABLE_BOTS").is_ok();

    let prod = std::env::var("PROD").is_ok();
    if !prod {
        log::info!("Running in dev mode, bots will be enabled");
    }

    let db_name = if prod { "prod" } else { "dummy" };

    let running = Arc::new(AtomicBool::new(true));
    let running_clone = running.clone();
    let running_clone_clone = running.clone();

    let db = web::Data::new(DB::new(db_name).map_err(|e| {
        log::error!("Failed to create db {:?}", e);
        std::io::Error::new(std::io::ErrorKind::Other, "Failed to create db")
    })?);

    // Task thread
    let db_clone = db.clone();
    std::thread::spawn(move || {
        while running_clone.load(Ordering::SeqCst) {
            run_all_tasks(&db_clone).unwrap();
            std::thread::sleep(std::time::Duration::from_secs(TASK_DELAY));
        }
    });

    if enable_bots {
        start_bot_manager(db.clone(), host.clone(), running_clone_clone);
    }

    log::info!("Starting server at http://{}:8080", &host);

    // Generate access codes (your existing code)
    if let Ok(_) = std::fs::read_to_string("access_codes.json") {
        log::info!("access_codes.json exists");
    } else {
        let access_codes = util::generate_access_codes(10000, &db).unwrap();
        let access_codes_json = serde_json::to_string(&access_codes).unwrap();
        std::fs::write("access_codes.json", access_codes_json).unwrap();
        log::info!("access_codes.json does not exist, created it");
    }

    let db_clone_for_flushing = db.clone();

    // Your existing HttpServer setup
    let result = HttpServer::new(move || {
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
            .service(rate)
            .service(report_bug)
            .service(fetch_notifications)
            .build()
    })
    .workers(4)
    .client_request_timeout(std::time::Duration::from_secs(600))
    .client_disconnect_timeout(std::time::Duration::from_secs(600))
    .bind((host, 8080))?
    .run()
    .await;

    println!("Flushing db");
    let res = db_clone_for_flushing.flush()?;
    println!("Flushed {:?}", res);

    result
}
