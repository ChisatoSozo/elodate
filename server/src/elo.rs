use rand::prelude::SliceRandom;
use rand::Rng;
use std::collections::{HashMap, HashSet};

use crate::user::{Gender, Preference, User};

pub fn update_elo(user: &mut User, users_map: &HashMap<String, User>) {
    let liked_by = user.liked_by.clone();
    let passed_by = user.passed_by.clone();

    //sum elo of liked_by users
    let liked_by_elo_sum: f64 = liked_by
        .iter()
        .map(|username| users_map.get(username).unwrap().elo as f64)
        .sum::<f64>()
        + 10000.0;

    //sum elo of passed_by users
    let passed_by_elo_sum: f64 = passed_by
        .iter()
        .map(|username| users_map.get(username).unwrap().elo as f64)
        .sum::<f64>()
        + 10000.0;

    //total elo of liked_by and passed_by users
    let total_elo = liked_by_elo_sum + passed_by_elo_sum;
    //liked percentage
    let liked_percentage = if total_elo == 0.0 {
        0.5
    } else {
        liked_by_elo_sum / total_elo
    };

    //elo update

    user.elo = 500.0 / (1.1 - liked_percentage) as f32;
}

#[test]
fn test_update_elo() {
    let usernames = (0..100)
        .map(|n| format!("user{}", n))
        .collect::<Vec<String>>();

    fn pick_n_random_users(n: usize, usernames: &Vec<String>) -> Vec<String> {
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

    let mut users_map = HashMap::new();

    for username in usernames.iter() {
        let user = User {
            username: username.clone(),
            hashed_password: "password".to_string(),
            birthdate: 0,
            gender: Gender {
                percent_male: 50,
                percent_female: 50,
            },
            seen: HashSet::new(),
            elo: 1000.0,
            liked_by: pick_n_random_users(rand_usize_between(0, 99), &usernames)
                .into_iter()
                .collect(),
            passed_by: pick_n_random_users(rand_usize_between(0, 99), &usernames)
                .into_iter()
                .collect(),
            preference: Preference {
                min_age: None,
                max_age: None,
                max_gender: None,
                min_gender: None,
            },
        };

        users_map.insert(username.clone(), user);
    }
    for _ in 0..100 {
        for username in usernames.iter() {
            let mut user = users_map.get_mut(username).unwrap().clone();
            update_elo(&mut user, &users_map);

            users_map.insert(username.clone(), user);
        }
        //print the max elo
        let max_elo = users_map
            .values()
            .max_by(|a, b| a.elo.partial_cmp(&b.elo).unwrap())
            .unwrap()
            .elo;
        println!("max elo: {}", max_elo);
    }
}

#[test]
fn run_test_100_times() {
    for _ in 0..100 {
        test_update_elo();
    }
}
