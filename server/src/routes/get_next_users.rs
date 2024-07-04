use actix_web::{Error, HttpRequest};

use paperclip::actix::{
    api_v2_operation, post,
    web::{self, Json},
};

use crate::{
    constants::USERS_PER_SET,
    db::DB,
    models::{
        api_models::{api_user::ApiUser, shared::ApiUuid},
        internal_models::internal_user::InternalUser,
    },
    routes::shared::route_body_mut_db,
};

#[api_v2_operation]
#[post("/get_next_users")]
pub fn get_next_users(
    db: web::Data<DB>,
    req: HttpRequest,
    body: web::Json<Vec<ApiUuid<InternalUser>>>,
) -> Result<Json<Vec<ApiUser>>, Error> {
    route_body_mut_db(db, req, body, |db, user, body| {
        let users = db.get_mutual_preference_users(&user)?;

        let seen = &user.seen;
        let users = users
            .into_iter()
            .filter(|u| !seen.contains(&u.uuid) && !body.contains(&u.uuid.clone().into()))
            .take(USERS_PER_SET)
            .map(|internal_user| ApiUser::from_internal(internal_user, Some(&user)))
            .collect::<Result<Vec<_>, _>>()?;
        Ok(users)
    })
}
