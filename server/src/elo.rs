// use std::error::Error;

use crate::models::internal_models::{
    internal_prefs::LabeledProperty,
    internal_user::{Action, InternalRating, TimestampedAction},
};

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

const MAX_MESSAGES_SENT_PER_DAY_REWARDED: usize = 20;
const MAX_MESSAGES_RECIEVED_PER_DAY_REWARDED: usize = 20;
const MAX_RATES_PER_DAY_REWARDED: usize = 20;

pub fn calc_elo(
    rates: &Vec<InternalRating>,
    actions: &Vec<TimestampedAction>,
    props: &Vec<LabeledProperty>,
) -> f32 {
    let mut liked = 0;
    let mut passed = 0;

    for rate in rates {
        match rate {
            InternalRating::LikedBy(_) => liked += 1,
            InternalRating::PassedBy(_) => passed += 1,
        }
    }

    let props_weight = props.len() as f32 / 1000.0;
    let num_props_filled = props.iter().filter(|prop| prop.value != -32768).count() as f32;
    let perc_props_filled = num_props_filled / props.len() as f32;

    passed += BEGINNING_LEFT_SWIPES;

    let mut message_value = 0.0;
    let mut recieve_message_value = 0.0;
    let mut rate_value = 0.0;

    let mut num_messages_recieved = 0;
    let mut num_messages_sent = 0;
    let mut num_rates = 0;

    for action in actions {
        match action.action {
            Action::SendMessage => {
                if num_messages_sent < MAX_MESSAGES_SENT_PER_DAY_REWARDED {
                    message_value += timestamp_weight_decay(action.timestamp, DECAY_DURATION)
                        / MAX_MESSAGES_SENT_PER_DAY_REWARDED as f32;
                    num_messages_sent += 1;
                }
            }
            Action::RecieveMessage => {
                if num_messages_recieved < MAX_MESSAGES_RECIEVED_PER_DAY_REWARDED {
                    recieve_message_value +=
                        timestamp_weight_decay(action.timestamp, DECAY_DURATION)
                            / MAX_MESSAGES_RECIEVED_PER_DAY_REWARDED as f32;
                    num_messages_recieved += 1;
                }
            }
            Action::Rate => {
                if num_rates < MAX_RATES_PER_DAY_REWARDED {
                    rate_value += timestamp_weight_decay(action.timestamp, DECAY_DURATION)
                        / MAX_RATES_PER_DAY_REWARDED as f32;
                    num_rates += 1;
                }
            }
        }
    }

    let perc_liked = liked as f32 / (liked + passed) as f32;

    let elo = perc_liked * LIKES_WEIGHT
        + message_value * MESSAGES_WEIGHT
        + recieve_message_value * RECIEVE_MESSAGES_WEIGHT
        + rate_value * RATE_WEIGHT;

    let elo = (1.0 - props_weight) * elo + props_weight * perc_props_filled;
    elo
}

const NUM_ELOS: usize = 16;
const ELO_LABELS: [&str; NUM_ELOS] = [
    "Bronze 1",
    "Bronze 2",
    "Silver 1",
    "Silver 2",
    "Gold 1",
    "Gold 2",
    "Platinum 1",
    "Platinum 2",
    "Emerald 1",
    "Emerald 2",
    "Sapphire 1",
    "Sapphire 2",
    "Ruby 1",
    "Ruby 2",
    "Diamond 1",
    "Diamond 2",
];

const ELO_THRESHOLDS: [f32; NUM_ELOS - 1] = [
    1.0 / 16.0,
    2.0 / 16.0,
    3.0 / 16.0,
    4.0 / 16.0,
    5.0 / 16.0,
    6.0 / 16.0,
    7.0 / 16.0,
    8.0 / 16.0,
    9.0 / 16.0,
    10.0 / 16.0,
    11.0 / 16.0,
    12.0 / 16.0,
    13.0 / 16.0,
    14.0 / 16.0,
    15.0 / 16.0,
];

pub fn elo_to_label(elo: f32) -> String {
    let mut i = 0;
    while i < NUM_ELOS - 1 && elo > ELO_THRESHOLDS[i] {
        i += 1;
    }
    ELO_LABELS[i].to_string()
}
