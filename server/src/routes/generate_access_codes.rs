use async_mutex::Mutex;

use actix_web::Error;

use crate::{db::DB, models};

use paperclip::actix::{api_v2_operation, get, web};

#[api_v2_operation]
#[get("/generate_access_codes")]
async fn generate_access_codes(db: web::Data<Mutex<DB>>) -> Result<String, Error> {
    let mut db = db.lock().await;
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
