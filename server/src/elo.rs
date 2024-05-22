// use std::error::Error;

// use crate::{
//     db::DB,
//     internal_models::{rating::InternalRating, shared::UuidModel, user::User},
// };

pub const ELO_SCALE: f64 = 500.0;
pub const ELO_SHIFT: f64 = 2.0;

pub fn calc_elo(liked_percentage: f64) -> u32 {
    (ELO_SCALE / (ELO_SHIFT - liked_percentage)) as u32
}

pub fn elo_max() -> u32 {
    calc_elo(1.0)
}

pub fn elo_min() -> u32 {
    calc_elo(0.0)
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

pub fn elo_to_label(elo: u32) -> String {
    let elo_perc = ((elo - elo_min()) as f32) / ((elo_max() - elo_min()) as f32);
    let mut i = 0;
    while i < (NUM_ELOS - 1) {
        if elo_perc.powf(0.8) < ELO_THRESHOLDS[i] {
            break;
        }
        i += 1;
    }
    ELO_LABELS[i].to_string()
}

// pub fn update_elo(user: User, db: &DB) -> Result<(), Box<dyn Error>> {
//     let liked_by = user
//         .ratings
//         .iter()
//         .filter_map(|r| match r {
//             InternalRating::LikedBy(user) => Some(user.clone()),
//             _ => None,
//         })
//         .collect::<Vec<UuidModel>>();
//     let passed_by = user
//         .ratings
//         .iter()
//         .filter_map(|r| match r {
//             InternalRating::PassedBy(user) => Some(user.clone()),
//             _ => None,
//         })
//         .collect::<Vec<UuidModel>>();

//     //sum elo of liked_by users
//     let liked_by_elo_sum: f64 = liked_by
//         .iter()
//         .map(|username| db.get_user(username).unwrap().unwrap().elo as f64)
//         .sum::<f64>()
//         + FUZZING_CONSTANT;

//     //sum elo of passed_by users
//     let passed_by_elo_sum: f64 = passed_by
//         .iter()
//         .map(|username| db.get_user(username).unwrap().unwrap().elo as f64)
//         .sum::<f64>()
//         + FUZZING_CONSTANT;

//     //total elo of liked_by and passed_by users
//     let total_elo = liked_by_elo_sum + passed_by_elo_sum;
//     //liked percentage
//     let liked_percentage = if total_elo == 0.0 {
//         0.5
//     } else {
//         liked_by_elo_sum / total_elo
//     };

//     //elo update
//     let new_elo = (ELO_SCALE / (ELO_SHIFT - liked_percentage)) as usize;

//     let new_user = User {
//         elo: new_elo as u32,
//         ..user
//     };

//     db.insert_user(&new_user)?;

//     Ok(())
// }
