use crate::models::internal_models::internal_user::InternalUser;

pub fn update_age(user: &mut InternalUser) {
    let now = chrono::Utc::now();
    let birthdate = chrono::DateTime::from_timestamp(user.birthdate, 0).unwrap();
    let age = (now - birthdate).num_days() / 365;
    user.props[0].value = age as i16;
}
