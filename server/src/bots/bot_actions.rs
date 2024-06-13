use crate::{
    db::DB,
    models::internal_models::{internal_user::InternalUser, shared::InternalUuid},
};

use super::fetch_users_and_swipe::fetch_users_and_swipe;

const BACKEND_URL: &str = "http://localhost:8080";

pub fn init_bots(db: &DB) -> Result<Vec<(String, String)>, Box<dyn std::error::Error>> {
    println!("Initializing bots");
    let mut uuids_jwts = vec![];
    for user in db.iter_obj::<InternalUser>("users")? {
        let user = user?;
        if user.bot_props.is_none() {
            continue;
        }
        let username = &user.username;
        let password = "asdfasdf".to_string();
        //post request to /login
        let login_url = format!("{}/login", BACKEND_URL);
        let login_body = format!(r#"{{"username":"{}","password":"{}"}}"#, username, password);
        let login_res = reqwest::blocking::Client::new()
            .post(&login_url)
            .body(login_body)
            .header("Content-Type", "application/json")
            .send()?;
        let login_res = login_res.text()?;
        let login_res: serde_json::Value = serde_json::from_str(&login_res)?;
        let jwt = login_res["jwt"].as_str().unwrap();
        let uuid = user.uuid.id.to_string();

        uuids_jwts.push((uuid, jwt.to_string()));
    }

    Ok(uuids_jwts)
}

pub fn post_with_jwt(
    path: &String,
    jwt: &String,
    body: String,
) -> Result<serde_json::Value, Box<dyn std::error::Error>> {
    let res = reqwest::blocking::Client::new()
        .post(&format!("{}/{}", BACKEND_URL, path))
        .body(body)
        .header("Content-Type", "application/json")
        .header("Authorization", format!("Bearer {}", jwt))
        .send()?;
    let res = res.text()?;
    let res: serde_json::Value = serde_json::from_str(&res)?;
    Ok(res)
}

pub fn run_all_bot_actions(
    db: &DB,
    uuid_jwt: &(String, String),
) -> Result<(), Box<dyn std::error::Error>> {
    let me_uuid: InternalUuid<InternalUser> = InternalUuid::from(uuid_jwt.0.clone());
    let me = me_uuid.load(db)?.ok_or("User not found")?;

    fetch_users_and_swipe(db, uuid_jwt, &me)?;
    Ok(())
}
