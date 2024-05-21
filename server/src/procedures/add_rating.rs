use crate::models::internal_models::shared::Save;
use crate::{
    db::DB,
    models::api_models::api_rating::Rating,
    models::internal_models::{
        internal_chat::InternalChat,
        internal_user::{InternalUser, Rated},
        shared::InternalUuid,
    },
};
use std::error::Error;

pub async fn add_rating(
    rating: Rating,
    source: InternalUuid<InternalUser>,
    target: InternalUuid<InternalUser>,
    db: &mut DB,
) -> Result<bool, Box<dyn Error>> {
    let source_user = source.load(db)?;
    let target_user = target.load(db)?;

    let mut source_user = match source_user {
        Some(user) => user,
        None => return Err("Source user not found".into()),
    };

    let mut target_user = match target_user {
        Some(user) => user,
        None => return Err("Target user not found".into()),
    };

    let mut mutual = false;

    if rating == Rating::Like {
        if source_user.is_liked_by(&target_user.uuid) {
            mutual = true;
            let chat = InternalChat::new(vec![source_user.uuid.clone(), target_user.uuid.clone()]);
            target_user.add_chat(&chat);
            source_user.add_chat(&chat);
            chat.save(db)?;
        }
    }

    let rated = match rating {
        Rating::Like => Rated::LikedBy(source_user.uuid.clone()),
        Rating::Pass => Rated::PassedBy(source_user.uuid.clone()),
    };

    let new_source_user = InternalUser {
        seen: source_user
            .seen
            .into_iter()
            .chain(std::iter::once(target_user.uuid.clone()))
            .collect(),
        ..source_user
    };

    let new_target_user = InternalUser {
        ratings: target_user
            .ratings
            .into_iter()
            .chain(std::iter::once(rated))
            .collect(),
        ..target_user
    };

    new_source_user.save(db)?;
    new_target_user.save(db)?;

    Ok(mutual)
}
