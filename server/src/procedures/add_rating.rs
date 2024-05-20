use std::error::Error;

use crate::{
    db::DB,
    models::{
        chat::Chat,
        rating::{Rated, Rating},
        shared::UuidModel,
        user::User,
    },
};

pub async fn add_rating(
    rating: Rating,
    source: UuidModel,
    target: UuidModel,
    db: &mut DB,
) -> Result<bool, Box<dyn Error>> {
    let mut source_user = db.get_user_by_uuid(&source)?;
    let mut target_user = db.get_user_by_uuid(&target)?;

    let mut mutual = false;

    if rating == Rating::Like {
        if source_user.is_liked_by(&target) {
            mutual = true;
            let chat = Chat::new(source.clone(), target.clone());
            db.insert_chat(&chat)?;

            target_user.add_chat(&chat);
            source_user.add_chat(&chat);
            db.insert_user(&target_user)?;
        }
    }

    let new_source_user = User {
        seen: source_user
            .seen
            .into_iter()
            .chain(std::iter::once(target))
            .collect(),
        ..source_user
    };

    let rated = match rating {
        Rating::Like => Rated::LikedBy(source),
        Rating::Pass => Rated::PassedBy(source),
    };

    let new_target_user = User {
        ratings: target_user
            .ratings
            .into_iter()
            .chain(std::iter::once(rated))
            .collect(),
        ..target_user
    };

    db.insert_user(&new_source_user)?;
    db.insert_user(&new_target_user)?;

    Ok(mutual)
}
