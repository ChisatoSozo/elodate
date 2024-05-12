use std::error::Error;

use crate::{
    constants::USERS_PER_SET,
    db::DB,
    elo::elo_to_label,
    models::{
        shared::UuidModel,
        user::{User, UserWithImagesAndElo},
    },
};

pub async fn get_user_set(
    db: &mut DB,
    user_uuid: &UuidModel,
    skip: Vec<UuidModel>,
) -> Result<Vec<UserWithImagesAndElo>, Box<dyn Error>> {
    let user = db.get_user_by_uuid(&user_uuid)?;
    let users = db.get_mutual_preference_users(&user)?;

    let seen = &user.seen;
    let users = users
        .into_iter()
        .filter(|u| !seen.contains(&u.uuid) && !skip.contains(&u.uuid))
        .take(USERS_PER_SET)
        .collect::<Vec<User>>();

    let users_with_images = users
        .into_iter()
        .map(|u| {
            db.get_images_from_user(&u.uuid)
                .map(|images| UserWithImagesAndElo {
                    user: u.public,
                    images: images,
                    elo: elo_to_label(u.elo),
                })
        })
        .collect::<Result<Vec<UserWithImagesAndElo>, Box<dyn Error>>>()?;

    Ok(users_with_images)
}
