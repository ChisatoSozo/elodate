use actix_web::{Error, HttpRequest};

use paperclip::actix::{
    api_v2_operation, post,
    web::{self, Json},
    Apiv2Schema,
};
use serde::{Deserialize, Serialize};

use crate::{
    db::DB,
    models::{
        api_models::{api_rating::ApiRating, shared::ApiUuid},
        internal_models::{
            internal_chat::InternalChat,
            internal_user::{
                Action, InternalRating, InternalUser, Notification, TimestampedAction,
            },
            shared::{InternalUuid, Save},
        },
    },
    routes::shared::route_body_mut_db,
};

#[derive(Debug, PartialEq, Serialize, Deserialize, Apiv2Schema)]
pub struct RatingWithTarget {
    pub target: ApiUuid<InternalUser>,
    pub rating: ApiRating,
}

#[api_v2_operation]
#[post("/rate")]
pub fn rate(
    db: web::Data<DB>,
    req: HttpRequest,
    body: web::Json<RatingWithTarget>,
) -> Result<Json<bool>, Error> {
    route_body_mut_db(db, req, body, |db, user, body| {
        let mut user = user;
        let rating = body.rating;
        let target = body.target;
        let target_internal_user_uuid: InternalUuid<InternalUser> = target.into();
        let target = target_internal_user_uuid.load(db).map_err(|e| {
            println!("Failed to get target user by uuid {:?}", e);
            actix_web::error::ErrorInternalServerError("Failed to get target user by uuid")
        })?;

        let mut target = match target {
            Some(target) => target,
            None => return Err(actix_web::error::ErrorNotFound("Target user not found")),
        };

        let mut mutual = false;

        if rating == ApiRating::Like {
            if user.is_liked_by(&target.uuid) {
                mutual = true;
                let chat = InternalChat::new(vec![user.uuid.clone(), target.uuid.clone()]);
                target.add_chat(&chat);
                user.add_chat(&chat);
                chat.save(db)?;
            }
        }

        let rated = match rating {
            ApiRating::Like => InternalRating::LikedBy(user.uuid.clone()),
            ApiRating::Pass => InternalRating::PassedBy(user.uuid.clone()),
        };

        let new_user = InternalUser {
            seen: user
                .seen
                .into_iter()
                .chain(std::iter::once(target.uuid.clone()))
                .collect(),
            actions: user
                .actions
                .into_iter()
                .chain(std::iter::once(TimestampedAction {
                    action: Action::Rate,
                    timestamp: chrono::Utc::now().timestamp(),
                }))
                .collect(),
            ..user
        };

        let new_target = InternalUser {
            ratings: target
                .ratings
                .into_iter()
                .chain(std::iter::once(rated))
                .collect(),
            notifications: if mutual {
                target
                    .notifications
                    .into_iter()
                    .chain(std::iter::once(Notification::Match(new_user.uuid.clone())))
                    .collect()
            } else {
                target.notifications
            },
            ..target
        };

        new_user.save(db)?;
        new_target.save(db)?;

        Ok(mutual)
    })
}
