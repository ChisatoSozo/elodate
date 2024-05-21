use std::error::Error;

use crate::models::internal_models::{internal_user::InternalUser, shared::InternalUuid};
use crate::{constants::USERS_PER_SET, db::DB};

pub async fn get_user_set(
    db: &mut DB,
    user_uuid: &InternalUuid<InternalUser>,
    skip: Vec<InternalUuid<InternalUser>>,
) -> Result<Vec<InternalUser>, Box<dyn Error>> {
    let user = user_uuid.load(db)?;
    let user = match user {
        Some(user) => user,
        None => return Err("User not found".into()),
    };

    let users = db.get_mutual_preference_users(&user)?;

    let seen = &user.seen;
    let users = users
        .into_iter()
        .filter(|u| !seen.contains(&u.uuid) && !skip.contains(&u.uuid))
        .take(USERS_PER_SET)
        .collect::<Vec<_>>();

    Ok(users)
}
