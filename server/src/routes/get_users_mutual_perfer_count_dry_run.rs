use actix_web::{Error, HttpRequest};

use paperclip::actix::{
    api_v2_operation, post,
    web::{self, Json},
    Apiv2Schema,
};
use serde::Deserialize;

use crate::{
    db::DB,
    models::internal_models::internal_prefs::{LabeledPreferenceRange, LabeledProperty},
    routes::shared::route_body_mut_db,
};

#[derive(Debug,  Deserialize, Apiv2Schema)]
pub struct PropsAndPrefs {
    pub props: Vec<LabeledProperty>,
    pub prefs: Vec<LabeledPreferenceRange>,
}

#[api_v2_operation]
#[post("/get_users_mutual_perfer_count_dry_run")]
pub fn get_users_mutual_perfer_count_dry_run(
    db: web::Data<DB>,
    req: HttpRequest,
    body: Json<PropsAndPrefs>,
) -> Result<Json<usize>, Error> {
    route_body_mut_db(db, req, body, |db, user, body| {
        let users_mutual_perfer_count =
            db.get_mutual_preference_users_count_direct(&body.props, &body.prefs, &user.seen)?;
        Ok(users_mutual_perfer_count)
    })
}
