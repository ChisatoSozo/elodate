// use std::error::Error;

use crate::models::internal_models::internal_user::{Action, InternalRating, TimestampedAction};

// use crate::{
//     db::DB,
//     internal_models::{rating::InternalRating, shared::UuidModel, user::User},
// };
pub const BEGINNING_LEFT_SWIPES: usize = 100;

pub const ELO_SCALE: f32 = 500.0;
pub const ELO_SHIFT: f32 = 2.0;

pub const LIKES_WEIGHT: f32 = 0.8;
pub const MESSAGES_WEIGHT: f32 = 0.1;
pub const RECIEVE_MESSAGES_WEIGHT: f32 = 0.05;
pub const RATE_WEIGHT: f32 = 0.05;

pub const DECAY_DURATION: i64 = 60 * 60 * 24 * 7;

//as now - timestamp approaches duration, the weight approaches 0, so the weight is 1 at timestamp = now, but it should decay slowly for the fisrt part, then faster
pub fn timestamp_weight_decay(timestamp: i64, duration: i64) -> f32 {
    let now = chrono::Utc::now().timestamp();
    let diff = now - timestamp;
    let diff = diff as f32;
    let duration = duration as f32;
    if diff > duration {
        return 0.0;
    }
    1.0 - (diff / duration)
}

pub fn calc_elo(rates: &Vec<InternalRating>, actions: &Vec<TimestampedAction>) -> f32 {
    let mut liked = 0;
    let mut passed = 0;

    for rate in rates {
        match rate {
            InternalRating::LikedBy(_) => liked += 1,
            InternalRating::PassedBy(_) => passed += 1,
        }
    }

    passed += BEGINNING_LEFT_SWIPES;

    let mut message_value = 0.0;
    let mut recieve_message_value = 0.0;
    let mut rate_value = 0.0;

    for action in actions {
        match action.action {
            Action::SendMessage => {
                message_value += timestamp_weight_decay(action.timestamp, DECAY_DURATION);
            }
            Action::RecieveMessage => {
                recieve_message_value += timestamp_weight_decay(action.timestamp, DECAY_DURATION);
            }
            Action::Rate => {
                rate_value += timestamp_weight_decay(action.timestamp, DECAY_DURATION);
            }
        }
    }

    let perc_liked = liked as f32 / (liked + passed) as f32;
    let elo = perc_liked * LIKES_WEIGHT
        + message_value * MESSAGES_WEIGHT
        + recieve_message_value * RECIEVE_MESSAGES_WEIGHT
        + rate_value * RATE_WEIGHT;
    elo
}

const NUM_ELOS: usize = 24;
const ELO_LABELS: [&str; NUM_ELOS] = [
    "Bronze 1",
    "Bronze 2",
    "Bronze 3",
    "Silver 1",
    "Silver 2",
    "Silver 3",
    "Gold 1",
    "Gold 2",
    "Gold 3",
    "Platinum 1",
    "Platinum 2",
    "Platinum 3",
    "Emerald 1",
    "Emerald 2",
    "Emerald 3",
    "Sapphire 1",
    "Sapphire 2",
    "Sapphire 3",
    "Ruby 1",
    "Ruby 2",
    "Ruby 3",
    "Diamond 1",
    "Diamond 2",
    "Diamond 3",
];

const ELO_THRESHOLDS: [f32; NUM_ELOS] = [
    0.0,
    1.0 / 24.0,
    2.0 / 24.0,
    3.0 / 24.0,
    4.0 / 24.0,
    5.0 / 24.0,
    6.0 / 24.0,
    7.0 / 24.0,
    8.0 / 24.0,
    9.0 / 24.0,
    10.0 / 24.0,
    11.0 / 24.0,
    12.0 / 24.0,
    13.0 / 24.0,
    14.0 / 24.0,
    15.0 / 24.0,
    16.0 / 24.0,
    17.0 / 24.0,
    18.0 / 24.0,
    19.0 / 24.0,
    20.0 / 24.0,
    21.0 / 24.0,
    22.0 / 24.0,
    23.0 / 24.0,
];

pub fn elo_to_label(elo: f32) -> String {
    let mut i = 0;
    while i < (NUM_ELOS - 1) {
        if elo < ELO_THRESHOLDS[i] {
            break;
        }
        i += 1;
    }
    ELO_LABELS[i].to_string()
}
