use crate::{
    db::DB,
    models::internal_models::{internal_user::InternalUser, shared::InternalUuid},
};

use super::{
    fetch_users_and_swipe::fetch_users_and_swipe,
    send_and_respond_to_chats::send_and_respond_to_chats,
};

pub fn init_bots(db: &DB, host: &str) -> Result<Vec<(String, String)>, Box<dyn std::error::Error>> {
    println!("Initializing bots");
    let backend_url = format!("http://{}:8080", host);
    let mut uuids_jwts = vec![];
    let mut i = 0;
    for user in db.iter_obj::<InternalUser>("users")? {
        if i % 10 == 0 {
            println!("Initialized {} bots", i);
        }
        i += 1;
        let user = user?;
        if user.bot_props.is_none() {
            continue;
        }
        let username = &user.username;
        let password = "asdfasdf".to_string();
        //post request to /login
        let login_url = format!("{}/login", backend_url);
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
    url: &str,
    client: &reqwest::blocking::Client,
    path: &String,
    jwt: &String,
    body: String,
) -> Result<serde_json::Value, Box<dyn std::error::Error>> {
    let res = {
        let res = client
            .post(&format!("http://{}:8080/{}", url, path))
            .body(body)
            .header("Content-Type", "application/json")
            .header("Authorization", format!("Bearer {}", jwt))
            .send();
        let res = match res {
            Ok(res) => {
                if !res.status().is_success() {
                    return Err(format!("Error posting to {}: {:#?}", path, res).into());
                }
                res
            }
            Err(e) => {
                return Err(format!("Error posting to {}: {:#?}", path, e).into());
            }
        };
        let res = res.text()?;
        let res: serde_json::Value = serde_json::from_str(&res)?;
        res
    };
    Ok(res)
}

pub fn run_all_bot_actions(
    client: &reqwest::blocking::Client,
    db: &DB,
    uuid_jwt: &(String, String),
    host: &str,
) -> Result<(), Box<dyn std::error::Error>> {
    let me_uuid: InternalUuid<InternalUser> = InternalUuid::from(uuid_jwt.0.clone());
    let me = me_uuid.load(db)?.ok_or("User not found")?;

    fetch_users_and_swipe(client, db, uuid_jwt, &me, host)?;
    send_and_respond_to_chats(client, db, uuid_jwt, &me, host)?;
    Ok(())
}
