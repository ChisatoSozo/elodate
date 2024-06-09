use crate::{
    elo::{calc_elo, BEGINNING_LEFT_SWIPES},
    models::internal_models::internal_user::{InternalRating, InternalUser},
};

pub fn update_elo(user: &mut InternalUser) {
    let num_swipe_left = user
        .ratings
        .iter()
        .filter(|r| match r {
            InternalRating::LikedBy(_) => false,
            InternalRating::PassedBy(_) => true,
        })
        .count() as u32
        + BEGINNING_LEFT_SWIPES;
    let num_swipe_right = user
        .ratings
        .iter()
        .filter(|r| match r {
            InternalRating::LikedBy(_) => true,
            InternalRating::PassedBy(_) => false,
        })
        .count() as u32;

    let perc_liked = num_swipe_right as f64 / (num_swipe_right + num_swipe_left) as f64;
    let elo = calc_elo(perc_liked);
    user.elo = elo;
}
