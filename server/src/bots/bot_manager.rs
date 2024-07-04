use crate::bots::bot_actions::{init_bots, run_all_bot_actions};
use crate::db::DB;
use log;
use std::sync::atomic::{AtomicBool, Ordering};
use std::time::Duration;
use std::{array, sync::Arc, thread};

const BOT_ACTION_DELAY: u64 = 1;
const NUM_BOT_THREADS: usize = 10;

pub fn start_bot_manager(
    db: actix_web::web::Data<DB>,
    host: String,
    running: Arc<AtomicBool>,
) -> thread::JoinHandle<()> {
    thread::spawn(move || {
        log::info!("Waiting 1 second before starting bots");
        thread::sleep(Duration::from_secs(1));

        let uuid_jwt = match init_bots(&db, &host) {
            Ok(uuids) => uuids,
            Err(e) => {
                log::error!("Failed to initialize bots: {:?}", e);
                return;
            }
        };

        let clients: [Arc<reqwest::blocking::Client>; NUM_BOT_THREADS] =
            array::from_fn(|_| Arc::new(reqwest::blocking::Client::new()));

        while running.load(Ordering::SeqCst) {
            log::info!("Running bots");
            let num_threads = 10;
            let total = uuid_jwt.len();
            let mut handles = vec![];

            for i in 0..num_threads {
                let db_clone = db.clone();
                let uuid_jwt = uuid_jwt.clone();
                let client_clone = clients[i].clone();
                let host = host.clone();
                let running_clone = running.clone();

                let handle = thread::spawn(move || {
                    let start = (i * total) / num_threads;
                    let end = std::cmp::min(((i + 1) * total) / num_threads, uuid_jwt.len());

                    for ix in start..end {
                        if !running_clone.load(Ordering::SeqCst) {
                            break;
                        }

                        let uuid_jwt = &uuid_jwt[ix];
                        match run_all_bot_actions(&client_clone, &db_clone, uuid_jwt, &host) {
                            Ok(_) => {}
                            Err(e) => log::info!("Bot failed to run: {:?}", e),
                        }
                        thread::sleep(Duration::from_secs(BOT_ACTION_DELAY));
                    }
                });
                handles.push(handle);
            }

            // Wait for all threads to complete
            for handle in handles {
                handle.join().unwrap();
            }

            // Break the loop if we're no longer running
            if !running.load(Ordering::SeqCst) {
                break;
            }
        }

        log::info!("Bot manager shutting down");
    })
}
