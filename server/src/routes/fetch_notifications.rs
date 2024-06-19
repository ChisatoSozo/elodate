use actix_web::Error;

use paperclip::actix::{
    api_v2_operation, post,
    web::{self, Json},
};

use crate::{
    db::DB,
    models::{api_models::api_user::ApiNotification, internal_models::shared::Save},
    routes::shared::route_body_mut_db,
};

#[api_v2_operation]
#[post("/fetch_notifications")]
pub fn fetch_notifications(
    db: web::Data<DB>,
    req: web::HttpRequest,
    body: Json<bool>,
) -> Result<Json<Vec<ApiNotification>>, Error> {
    route_body_mut_db(db, req, body, |db, mut user, _| {
        //is this user in this chat?

        let notifications: Vec<ApiNotification> =
            user.notifications.into_iter().map(|n| n.into()).collect();

        user.notifications = vec![];
        user.save(db)?;

        Ok(notifications)
    })
}
