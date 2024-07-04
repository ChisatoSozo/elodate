use crate::{
    db::DB,
    models::{
        api_models::api_user::ApiUser,
        internal_models::{internal_user::InternalUser, shared::InternalUuid},
    },
};

use super::bot_actions::post_with_jwt;

pub fn fetch_users_and_swipe(
    client: &reqwest::blocking::Client,
    db: &DB,
    uuid_jwt: &(String, String),
    me: &InternalUser,
    host: &str,
) -> Result<(), Box<dyn std::error::Error>> {
    let users = post_with_jwt(
        host,
        client,
        &"get_next_users".to_string(),
        &uuid_jwt.1,
        r#"[]"#.to_string(),
    );

    match users {
        Ok(users) => {
            for user in users.as_array().ok_or("Error fetching users")? {
                let user: ApiUser = serde_json::from_value(user.clone())?;
                let internal_user_uuid: InternalUuid<_> = user.uuid.clone().into();
                let internal_user = internal_user_uuid.load(db)?;
                let likelihood_to_swipe_right = me
                    .bot_props
                    .as_ref()
                    .ok_or(format!("Bot props not found for user: {}", me.username))?
                    .likelihood_to_swipe_right;
                let likelihood_to_be_swiped_right = internal_user
                    .ok_or("User not found")?
                    .bot_props
                    .map(|props| props.likelihood_to_recieve_like)
                    .unwrap_or(0.5);

                let total_likelihood =
                    (likelihood_to_swipe_right * likelihood_to_be_swiped_right).sqrt();

                let should_swipe_right = rand::random::<f64>() < total_likelihood as f64;

                if should_swipe_right {
                    let _ = post_with_jwt(
                        host,
                        client,
                        &"rate".to_string(),
                        &uuid_jwt.1,
                        format!(r#"{{"target":"{}","rating":"Like"}}"#, user.uuid.id),
                    )?;
                } else {
                    let _ = post_with_jwt(
                        host,
                        client,
                        &"rate".to_string(),
                        &uuid_jwt.1,
                        format!(r#"{{"target":"{}","rating":"Pass"}}"#, user.uuid.id),
                    )?;
                }
            }
        }
        Err(e) => {
            log::error!("Error fetching users: {}", e);
        }
    }
    Ok(())
}
