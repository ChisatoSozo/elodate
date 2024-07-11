use crate::{elo::calc_elo, models::internal_models::internal_user::InternalUser};

pub fn update_elo(user: &mut InternalUser) {
    let elo = calc_elo(&user.ratings, &user.actions, &user.props);
    user.elo = elo;
}
