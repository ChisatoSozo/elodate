use std::error::Error;

use crate::{
    db::DB,
    models::{
        shared::UuidModel,
        user::{Rating, User},
    },
};

const ELO_SCALE: f64 = 500.0;
const ELO_SHIFT: f64 = 2.0;
const FUZZING_CONSTANT: f64 = 500.0;

const ELO_MAX: f32 = (ELO_SCALE / (ELO_SHIFT - 1.0)) as f32;
const ELO_MIN: f32 = (ELO_SCALE / (ELO_SHIFT)) as f32;

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

pub fn elo_to_label(elo: usize) -> String {
    let elo = elo as f32;
    let elo_perc = (elo - ELO_MIN) / (ELO_MAX - ELO_MIN);
    let mut i = 0;
    while i < NUM_ELOS {
        if elo_perc.powf(0.8) < ELO_THRESHOLDS[i] {
            break;
        }
        i += 1;
    }
    ELO_LABELS[i].to_string()
}

pub fn update_elo(user: User, db: &mut DB) -> Result<(), Box<dyn Error>> {
    let liked_by = user
        .ratings
        .iter()
        .filter_map(|r| match r {
            Rating::LikedBy(user) => Some(user.clone()),
            _ => None,
        })
        .collect::<Vec<UuidModel>>();
    let passed_by = user
        .ratings
        .iter()
        .filter_map(|r| match r {
            Rating::PassedBy(user) => Some(user.clone()),
            _ => None,
        })
        .collect::<Vec<UuidModel>>();

    //sum elo of liked_by users
    let liked_by_elo_sum: f64 = liked_by
        .iter()
        .map(|username| db.get_user_by_uuid(username).unwrap().elo as f64)
        .sum::<f64>()
        + FUZZING_CONSTANT;

    //sum elo of passed_by users
    let passed_by_elo_sum: f64 = passed_by
        .iter()
        .map(|username| db.get_user_by_uuid(username).unwrap().elo as f64)
        .sum::<f64>()
        + FUZZING_CONSTANT;

    //total elo of liked_by and passed_by users
    let total_elo = liked_by_elo_sum + passed_by_elo_sum;
    //liked percentage
    let liked_percentage = if total_elo == 0.0 {
        0.5
    } else {
        liked_by_elo_sum / total_elo
    };

    //elo update
    let new_elo = (ELO_SCALE / (ELO_SHIFT - liked_percentage)) as usize;

    let new_user = User {
        elo: new_elo,
        ..user
    };

    db.insert_user(&new_user)?;

    Ok(())
}

#[test]
fn test_update_elo() {
    use crate::models::user::{Gender, Preference};
    use rand::prelude::SliceRandom;
    use rand::Rng;
    use std::collections::{HashMap, HashSet};
    let usernames = (0..1000)
        .map(|_| UuidModel::new())
        .collect::<Vec<UuidModel>>();
    //delete db/test
    let _ = std::fs::remove_dir_all("db/test");

    let mut db = DB::new("test");
    println!("done upserting");

    fn pick_n_random_users(n: usize, usernames: &Vec<UuidModel>) -> Vec<UuidModel> {
        let mut rng = rand::thread_rng();
        let mut usernames = usernames.clone();
        usernames.shuffle(&mut rng);
        usernames.truncate(n);
        usernames
    }

    fn rand_usize_between(min: usize, max: usize) -> usize {
        let mut rng = rand::thread_rng();
        rng.gen_range(min..max)
    }

    for username in usernames.iter() {
        let users: Vec<_> = pick_n_random_users(rand_usize_between(0, 99), &usernames)
            .into_iter()
            .collect();

        fn rand_bool() -> bool {
            let mut rng = rand::thread_rng();
            rng.gen()
        }

        let ratings: Vec<Rating> = users
            .iter()
            .map(|username| {
                if rand_bool() {
                    Rating::LikedBy(username.clone())
                } else {
                    Rating::PassedBy(username.clone())
                }
            })
            .collect();

        let user = User {
            display_name: username.to_string(),
            username: username.to_string(),
            password: "password".to_string(),
            birthdate: 0,
            gender: Gender {
                percent_male: 50,
                percent_female: 50,
            },
            seen: HashSet::new(),
            elo: 1000,
            preference: Preference {
                min_age: None,
                max_age: None,
                max_gender: None,
                min_gender: None,
            },
            uuid: username.clone(),

            ratings,
            chats: vec![],
        };

        db.insert_user(&user).unwrap();
    }
    for _ in 0..10 {
        for username in usernames.iter() {
            let user = db.get_user_by_uuid(username).unwrap().clone();
            update_elo(user, &mut db).unwrap();
        }
    }

    let labels = usernames
        .iter()
        .map(|username| {
            let user = db.get_user_by_uuid(username).unwrap();
            elo_to_label(user.elo)
        })
        .collect::<Vec<String>>();

    let labels_count = labels.iter().fold(HashMap::new(), |mut acc, label| {
        *acc.entry(label.clone()).or_insert(0) += 1;
        acc
    });

    //for every ELO_LABEL, print the count
    for label in ELO_LABELS.iter() {
        println!("{}: {}", label, labels_count.get(*label).unwrap_or(&0));
    }
}

#[test]
fn run_test_100_times() {
    for _ in 0..100 {
        test_update_elo();
    }
}
