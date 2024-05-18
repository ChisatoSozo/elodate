use crate::{test::fake::FakeGen, vec::shared::VectorSearch};
use std::array;
use std::collections::{HashMap, HashSet};

use paperclip::actix::Apiv2Schema;
use rand::rngs::ThreadRng;
use rand::Rng;
use rand_distr::Distribution;
use rand_distr::Normal;
use serde::{Deserialize, Serialize};

use crate::{db::DB, vec::shared::Bbox};

use super::{
    shared::UuidModel,
    user::{User, UserPublicFields},
};

#[derive(Debug, Serialize, Deserialize, Apiv2Schema, Clone, PartialEq, Eq)]
pub struct PreferenceRange {
    pub min: i16,
    pub max: i16,
}

pub struct UserProperties {
    pub age: i16,
    pub percent_male: i16,
    pub percent_female: i16,
    pub latitude: i16,
    pub longitude: i16,
    pub additional_preferences: HashMap<String, i16>,
}

impl UserProperties {
    pub fn get_vector(&self) -> [i16; PREFERENCE_CARDINALITY] {
        let mut vector = [0 as i16; PREFERENCE_CARDINALITY];

        vector[0] = self.age;
        vector[1] = self.percent_male;
        vector[2] = self.percent_female;
        vector[3] = self.latitude;
        vector[4] = self.longitude;

        let mut index = 5; // Start from the 6th element in the array

        for (_, value) in self.additional_preferences.iter() {
            if index < PREFERENCE_CARDINALITY {
                vector[index] = *value;
                index += 1;
            } else {
                break;
            }
        }

        vector
    }
}

#[derive(Debug, Serialize, Deserialize, Apiv2Schema, Clone, PartialEq, Eq)]
pub struct Preference {
    pub age: PreferenceRange,
    pub percent_male: PreferenceRange,
    pub percent_female: PreferenceRange,
    pub latitude: PreferenceRange,
    pub longitude: PreferenceRange,
    pub additional_preferences: HashMap<String, PreferenceRange>,
}

impl FakeGen<UserProperties> for Preference {
    fn fake_gen(user: &UserProperties) -> Self {
        let mut rng = rand::thread_rng();
        let age = sample_range_from_additional_preference_and_prop(
            &ADDITIONAL_PREFERENCES[0],
            user.age,
            &mut rng,
        );
        let percent_male = sample_range_from_additional_preference_and_prop(
            &ADDITIONAL_PREFERENCES[1],
            user.percent_male,
            &mut rng,
        );
        let percent_female = sample_range_from_additional_preference_and_prop(
            &ADDITIONAL_PREFERENCES[2],
            user.percent_female,
            &mut rng,
        );
        let latitude = PreferenceRange {
            min: -32768,
            max: 32767,
        };
        let longitude = PreferenceRange {
            min: -32768,
            max: 32767,
        };

        let mut additional_preferences = HashMap::new();
        let mut index = 5; // Start from the 6th element in the array

        while index < PREFERENCE_CARDINALITY {
            let preference = ADDITIONAL_PREFERENCES[index].sample_range(user, &mut rng);
            additional_preferences
                .insert(ADDITIONAL_PREFERENCES[index].name.to_string(), preference);
            index += 1;
        }

        Preference {
            age,
            percent_male,
            percent_female,
            latitude,
            longitude,
            additional_preferences,
        }
    }
}

impl Preference {
    pub fn get_bbox(&self) -> Bbox<PREFERENCE_CARDINALITY> {
        let mut min_vals = [0 as i16; PREFERENCE_CARDINALITY];
        let mut max_vals = [0 as i16; PREFERENCE_CARDINALITY];

        // Adding the core preferences
        min_vals[0] = self.age.min;
        max_vals[0] = self.age.max;

        min_vals[1] = self.percent_male.min;
        max_vals[1] = self.percent_male.max;

        min_vals[2] = self.percent_female.min;
        max_vals[2] = self.percent_female.max;

        min_vals[3] = self.latitude.min;
        max_vals[3] = self.latitude.max;

        min_vals[4] = self.longitude.min;
        max_vals[4] = self.longitude.max;

        // Adding the additional preferences
        let mut index = 5; // Start from the 6th element in the array

        for (_, preference) in self.additional_preferences.iter() {
            if index < PREFERENCE_CARDINALITY {
                min_vals[index] = preference.min;
                max_vals[index] = preference.max;
                index += 1;
            } else {
                break;
            }
        }
        Bbox {
            min: min_vals,
            max: max_vals,
        }
    }
}

impl DB {
    fn get_users_who_prefer_me_direct(
        &mut self,
        user: &UserPublicFields,
        seen: &HashSet<UuidModel>,
    ) -> HashSet<String> {
        self.vec_index
            .search_inverse(
                &user.get_my_vector(),
                Some(&seen.iter().map(|u| u.0.clone()).collect()),
            )
            .map(|u| u.label)
            .collect()
    }

    fn get_users_who_i_prefer_direct(
        &mut self,
        preference: &Preference,
        seen: &HashSet<UuidModel>,
    ) -> HashSet<String> {
        self.vec_index
            .search(
                &preference.get_bbox(),
                Some(&seen.iter().map(|u| u.0.clone()).collect()),
            )
            .map(|u| u.label)
            .collect()
    }

    pub fn get_mutual_preference_users_direct(
        &mut self,
        user: &UserPublicFields,
        seen: &HashSet<UuidModel>,
    ) -> Vec<User> {
        let users_who_prefer_me = self.get_users_who_prefer_me_direct(user, &seen);
        let users_who_i_prefer = self.get_users_who_i_prefer_direct(&user.preference, &seen);

        users_who_prefer_me
            .intersection(&users_who_i_prefer)
            .map(|u| self.get_user_by_uuid(&UuidModel(u.to_string())).unwrap())
            .collect()
    }

    pub fn get_mutual_preference_users_count_direct(
        &mut self,
        user: &UserPublicFields,
        preference: &Preference,
        seen: &HashSet<UuidModel>,
    ) -> usize {
        let users_who_prefer_me = self.get_users_who_prefer_me_direct(user, &seen);
        let users_who_i_prefer = self.get_users_who_i_prefer_direct(preference, &seen);

        users_who_prefer_me
            .intersection(&users_who_i_prefer)
            .count()
    }

    pub fn get_users_i_prefer_count_direct(
        &mut self,
        preference: &Preference,
        seen: &HashSet<UuidModel>,
    ) -> usize {
        self.get_users_who_i_prefer_direct(preference, &seen).len()
    }

    pub fn get_users_who_prefer_me(&mut self, user: &User) -> HashSet<String> {
        self.get_users_who_prefer_me_direct(&user.public, &user.seen)
    }

    pub fn get_users_who_i_prefer(&mut self, user: &User) -> HashSet<String> {
        self.get_users_who_i_prefer_direct(&user.public.preference, &user.seen)
    }

    pub fn get_mutual_preference_users(&mut self, user: &User) -> Vec<User> {
        self.get_mutual_preference_users_direct(&user.public, &user.seen)
    }

    pub fn get_mutual_preference_users_count(&mut self, user: &User) -> usize {
        self.get_mutual_preference_users_count_direct(
            &user.public,
            &user.public.preference,
            &user.seen,
        )
    }

    pub fn get_users_i_prefer_count(&mut self, user: &User) -> usize {
        self.get_users_i_prefer_count_direct(&user.public.preference, &user.seen)
    }
}

#[derive(Debug, Serialize, Deserialize, Apiv2Schema, Clone, PartialEq)]
pub struct AdditionalPreference<'a> {
    pub name: &'a str,
    pub min: i16,
    pub max: i16,
    pub mean: f64,
    pub std_dev: f64,
    pub mean_alteration: MeanAlteration,
    pub std_dev_alteration: StdDevAlteration,
    pub linear_mapping: Option<LinearMapping>,
    pub optional: bool,
    pub probability_to_be_none: f64,
    pub labels: Option<[&'a str; 5]>,
}

impl AdditionalPreference<'_> {
    pub fn get_public(&self) -> AdditionalPreferencePublic {
        AdditionalPreferencePublic {
            name: self.name.to_string(),
            min: self.min,
            max: self.max,
            linear_mapping: self.linear_mapping.clone(),
            labels: self.labels.map(|labels| {
                let mut new_labels = array::from_fn::<String, 5, _>(|_| "".to_string());
                for i in 0..5 {
                    new_labels[i] = labels[i].to_string();
                }
                new_labels
            }),
            optional: self.optional,
        }
    }
}

#[derive(Debug, Serialize, Deserialize, Apiv2Schema, Clone, PartialEq)]
pub struct AdditionalPreferencePublic {
    pub name: String,
    pub min: i16,
    pub max: i16,
    pub linear_mapping: Option<LinearMapping>,
    pub labels: Option<[String; 5]>,
    pub optional: bool,
}

fn f64_to_i16(value: f64, additional_preference: &AdditionalPreference) -> i16 {
    if let Some(linear_mapping) = &additional_preference.linear_mapping {
        let real_min = linear_mapping.real_min;
        let real_max = linear_mapping.real_max;
        let value = (value - real_min) / (real_max - real_min) * 32767.0;
        value as i16
    } else {
        value as i16
    }
}

fn sample_range_from_additional_preference_and_prop(
    additional_preference: &AdditionalPreference,
    prop: i16,
    rng: &mut ThreadRng,
) -> PreferenceRange {
    //get if none
    if rng.gen_range(0.0..1.0) < additional_preference.probability_to_be_none {
        return PreferenceRange {
            min: i16::MIN,
            max: i16::MAX,
        };
    }

    let mut mean = f64_to_i16(additional_preference.mean, additional_preference) as f64;
    let mut std_dev = f64_to_i16(additional_preference.std_dev, additional_preference) as f64;

    match &additional_preference.mean_alteration {
        MeanAlteration::Increase => mean += prop as f64,
        MeanAlteration::Decrease => mean -= prop as f64,
        MeanAlteration::Set => mean = prop as f64,
        MeanAlteration::FromValue(linear) => mean = linear.slope * prop as f64 + linear.intercept,
        _ => (),
    }

    match &additional_preference.std_dev_alteration {
        StdDevAlteration::FromMean(linear) => {
            std_dev = linear.slope * mean as f64 + linear.intercept
        }
        StdDevAlteration::FromValue(linear) => {
            std_dev = linear.slope * prop as f64 + linear.intercept
        }
        _ => (),
    }

    let normal = Normal::new(mean, std_dev).unwrap();
    // sample 5 times and get the min and max
    let mut min = additional_preference.max;
    let mut max = additional_preference.min;
    for _ in 0..5 {
        let sample = normal.sample(rng) as i16;
        if sample < min {
            min = sample;
        }
        if sample > max {
            max = sample;
        }
    }

    if max < min {
        let temp = max;
        max = min;
        min = temp;
    }

    if min < additional_preference.min {
        min = additional_preference.min;
    }

    if max > additional_preference.max {
        max = additional_preference.max;
    }

    PreferenceRange { min, max }
}

impl<'a> AdditionalPreference<'a> {
    pub fn sample(&self, rng: &mut ThreadRng) -> i16 {
        //get if none
        if rng.gen_range(0.0..1.0) < self.probability_to_be_none {
            return i16::MIN;
        }

        let mean = f64_to_i16(self.mean, self) as f64;
        let std_dev = f64_to_i16(self.std_dev, self) as f64;

        let normal = Normal::new(mean, std_dev).unwrap();
        let sample = normal.sample(rng) as i16;
        if sample < self.min {
            self.min
        } else if sample > self.max {
            self.max
        } else {
            sample as i16
        }
    }

    pub fn sample_range(&self, user: &UserProperties, rng: &mut ThreadRng) -> PreferenceRange {
        let prop = user.additional_preferences.get(self.name).unwrap();
        sample_range_from_additional_preference_and_prop(self, *prop, rng)
    }
}

#[derive(Debug, Serialize, Deserialize, Apiv2Schema, Clone, PartialEq)]
pub enum MeanAlteration {
    None,
    Increase,
    Decrease,
    Set,
    FromValue(Linear),
}

#[derive(Debug, Serialize, Deserialize, Apiv2Schema, Clone, PartialEq)]
pub struct Linear {
    pub slope: f64,
    pub intercept: f64,
}

#[derive(Debug, Serialize, Deserialize, Apiv2Schema, Clone, PartialEq)]
pub enum StdDevAlteration {
    None,
    FromMean(Linear),
    FromValue(Linear),
}

#[derive(Debug, Serialize, Deserialize, Apiv2Schema, Clone, PartialEq)]
pub struct LinearMapping {
    pub real_min: f64,
    pub real_max: f64,
}

const P_NONE: f64 = 1.0;

pub static ADDITIONAL_PREFERENCES: [AdditionalPreference; PREFERENCE_CARDINALITY] = [
    AdditionalPreference {
        name: "age",
        min: 18,
        max: 120,
        mean: 35.0,
        std_dev: 20.0,
        mean_alteration: MeanAlteration::Set,
        std_dev_alteration: StdDevAlteration::FromMean(Linear {
            slope: 0.1,
            intercept: 0.0,
        }),
        linear_mapping: None,
        optional: false,
        labels: None,
        probability_to_be_none: 0.0,
    },
    AdditionalPreference {
        name: "percent_male",
        min: 0,
        max: 100,
        mean: 50.0,
        std_dev: 25.0,
        mean_alteration: MeanAlteration::FromValue(Linear {
            slope: -1.0,
            intercept: 100.0,
        }),
        std_dev_alteration: StdDevAlteration::None,
        linear_mapping: None,
        optional: false,
        labels: None,
        probability_to_be_none: 0.0,
    },
    AdditionalPreference {
        name: "percent_female",
        min: 0,
        max: 100,
        mean: 50.0,
        std_dev: 25.0,
        mean_alteration: MeanAlteration::FromValue(Linear {
            slope: -1.0,
            intercept: 100.0,
        }),
        std_dev_alteration: StdDevAlteration::None,
        linear_mapping: None,
        optional: false,
        labels: None,
        probability_to_be_none: 0.0,
    },
    AdditionalPreference {
        name: "latitude",
        min: -32767,
        max: 32767,
        mean: 0.0,
        std_dev: 10000.0,
        mean_alteration: MeanAlteration::Set,
        std_dev_alteration: StdDevAlteration::None,
        linear_mapping: Some(LinearMapping {
            real_min: -90.0,
            real_max: 90.0,
        }),
        optional: false,
        labels: None,
        probability_to_be_none: 0.0,
    },
    AdditionalPreference {
        name: "longitude",
        min: -32767,
        max: 32767,
        mean: 0.0,
        std_dev: 0.0,
        mean_alteration: MeanAlteration::Set,
        std_dev_alteration: StdDevAlteration::None,
        linear_mapping: Some(LinearMapping {
            real_min: -180.0,
            real_max: 180.0,
        }),
        optional: false,
        labels: None,
        probability_to_be_none: 0.0,
    },
    AdditionalPreference {
        name: "salary_per_year",
        min: 0,
        max: 100,
        mean: 50000.0,
        std_dev: 25000.0,
        mean_alteration: MeanAlteration::Set,
        std_dev_alteration: StdDevAlteration::FromMean(Linear {
            slope: 0.3,
            intercept: 0.0,
        }),
        linear_mapping: Some(LinearMapping {
            real_min: 0.0,
            real_max: 1000000.0,
        }),
        optional: true,
        labels: None,
        probability_to_be_none: P_NONE,
    },
    AdditionalPreference {
        name: "height_cm",
        min: 0,
        max: 250,
        mean: 175.0,
        std_dev: 10.0,
        mean_alteration: MeanAlteration::Set,
        std_dev_alteration: StdDevAlteration::FromMean(Linear {
            slope: 0.1,
            intercept: 0.0,
        }),
        linear_mapping: None,
        optional: true,
        labels: None,
        probability_to_be_none: P_NONE,
    },
    AdditionalPreference {
        name: "bmi",
        min: 0,
        max: 100,
        mean: 25.0,
        std_dev: 5.0,
        mean_alteration: MeanAlteration::Set,
        std_dev_alteration: StdDevAlteration::FromMean(Linear {
            slope: 0.1,
            intercept: 0.0,
        }),
        linear_mapping: None,
        optional: true,
        labels: None,
        probability_to_be_none: P_NONE,
    },
    AdditionalPreference {
        name: "number_of_times_a_week_you_want_to_have_sex",
        min: 0,
        max: 100,
        mean: 2.0,
        std_dev: 2.0,
        mean_alteration: MeanAlteration::Set,
        std_dev_alteration: StdDevAlteration::FromMean(Linear {
            slope: 0.1,
            intercept: 0.0,
        }),
        linear_mapping: None,
        optional: true,
        labels: None,
        probability_to_be_none: P_NONE,
    },
    AdditionalPreference {
        name: "is_trans",
        min: 0,
        max: 1,
        mean: 0.0,
        std_dev: 0.4,
        mean_alteration: MeanAlteration::Set,
        std_dev_alteration: StdDevAlteration::None,
        linear_mapping: None,
        optional: true,
        labels: None,
        probability_to_be_none: P_NONE,
    },
    AdditionalPreference {
        name: "political_affiliation",
        min: 0,
        max: 5,
        mean: 2.0,
        std_dev: 1.0,
        mean_alteration: MeanAlteration::Set,
        std_dev_alteration: StdDevAlteration::FromMean(Linear {
            slope: 0.1,
            intercept: 0.0,
        }),
        linear_mapping: None,
        optional: true,
        labels: Some([
            "Leftist",
            "Liberal",
            "Centrist",
            "Conservative",
            "Traditionalist",
        ]),
        probability_to_be_none: P_NONE,
    },
    AdditionalPreference {
        name: "fitness_level",
        min: 0,
        max: 5,
        mean: 2.0,
        std_dev: 1.0,
        mean_alteration: MeanAlteration::Set,
        std_dev_alteration: StdDevAlteration::FromMean(Linear {
            slope: 0.1,
            intercept: 0.0,
        }),
        linear_mapping: None,
        optional: true,
        labels: Some(["Couch potato", "Sedentary", "Average", "Fit", "Athlete"]),
        probability_to_be_none: P_NONE,
    },
    AdditionalPreference {
        name: "number_of_children",
        min: 0,
        max: 10,
        mean: 1.0,
        std_dev: 1.0,
        mean_alteration: MeanAlteration::Set,
        std_dev_alteration: StdDevAlteration::FromMean(Linear {
            slope: 0.1,
            intercept: 0.0,
        }),
        linear_mapping: None,
        optional: true,
        labels: None,
        probability_to_be_none: P_NONE,
    },
    AdditionalPreference {
        name: "number_of_dogs",
        min: 0,
        max: 10,
        mean: 0.0,
        std_dev: 1.0,
        mean_alteration: MeanAlteration::Set,
        std_dev_alteration: StdDevAlteration::FromMean(Linear {
            slope: 0.1,
            intercept: 0.0,
        }),
        linear_mapping: None,
        optional: true,
        labels: None,
        probability_to_be_none: P_NONE,
    },
    AdditionalPreference {
        name: "number_of_cats",
        min: 0,
        max: 10,
        mean: 0.0,
        std_dev: 1.0,
        mean_alteration: MeanAlteration::Set,
        std_dev_alteration: StdDevAlteration::FromMean(Linear {
            slope: 0.1,
            intercept: 0.0,
        }),
        linear_mapping: None,
        optional: true,
        labels: None,
        probability_to_be_none: P_NONE,
    },
    AdditionalPreference {
        name: "vegetarianness",
        min: 0,
        max: 5,
        mean: 2.0,
        std_dev: 1.0,
        mean_alteration: MeanAlteration::Set,
        std_dev_alteration: StdDevAlteration::FromMean(Linear {
            slope: 0.1,
            intercept: 0.0,
        }),
        linear_mapping: None,
        optional: true,
        labels: Some([
            "Carnivore",
            "Omnivore",
            "Pescatarian",
            "Vegetarian",
            "Vegan",
        ]),
        probability_to_be_none: P_NONE,
    },
    AdditionalPreference {
        name: "gamerness_level",
        min: 0,
        max: 5,
        mean: 2.0,
        std_dev: 1.0,
        mean_alteration: MeanAlteration::Set,
        std_dev_alteration: StdDevAlteration::FromMean(Linear {
            slope: 0.1,
            intercept: 0.0,
        }),
        linear_mapping: None,
        optional: true,
        labels: Some([
            "I don't play games",
            "Casual",
            "Average",
            "Hardcore",
            "Professional",
        ]),
        probability_to_be_none: P_NONE,
    },
    AdditionalPreference {
        name: "extroversion_level",
        min: 0,
        max: 5,
        mean: 2.0,
        std_dev: 1.0,
        mean_alteration: MeanAlteration::Set,
        std_dev_alteration: StdDevAlteration::FromMean(Linear {
            slope: 0.1,
            intercept: 0.0,
        }),
        linear_mapping: None,
        optional: true,
        labels: Some([
            "Introvert",
            "Ambivert",
            "Average",
            "Extrovert",
            "Life of the party",
        ]),
        probability_to_be_none: P_NONE,
    },
    AdditionalPreference {
        name: "how_much_you_want_to_go_outside",
        min: 0,
        max: 5,
        mean: 2.0,
        std_dev: 1.0,
        mean_alteration: MeanAlteration::Set,
        std_dev_alteration: StdDevAlteration::FromMean(Linear {
            slope: 0.1,
            intercept: 0.0,
        }),
        linear_mapping: None,
        optional: true,
        labels: Some([
            "Agoraphobic",
            "Homebody",
            "Average",
            "Outdoorsy",
            "Wanderlust",
        ]),
        probability_to_be_none: P_NONE,
    },
    AdditionalPreference {
        name: "how_much_you_want_to_travel",
        min: 0,
        max: 5,
        mean: 2.0,
        std_dev: 1.0,
        mean_alteration: MeanAlteration::Set,
        std_dev_alteration: StdDevAlteration::FromMean(Linear {
            slope: 0.1,
            intercept: 0.0,
        }),
        linear_mapping: None,
        optional: true,
        labels: Some([
            "I don't want to travel",
            "Homebody",
            "Average",
            "Traveler",
            "Wanderlust",
        ]),
        probability_to_be_none: P_NONE,
    },
    AdditionalPreference {
        name: "how_cleanly_are_you",
        min: 0,
        max: 5,
        mean: 2.0,
        std_dev: 1.0,
        mean_alteration: MeanAlteration::Set,
        std_dev_alteration: StdDevAlteration::FromMean(Linear {
            slope: 0.1,
            intercept: 0.0,
        }),
        linear_mapping: None,
        optional: true,
        labels: Some([
            "Slob",
            "Average",
            "Clean",
            "Neat freak",
            "Obsessive-compulsive",
        ]),
        probability_to_be_none: P_NONE,
    },
    AdditionalPreference {
        name: "hoarder_level",
        min: 0,
        max: 5,
        mean: 2.0,
        std_dev: 1.0,
        mean_alteration: MeanAlteration::Set,
        std_dev_alteration: StdDevAlteration::FromMean(Linear {
            slope: 0.1,
            intercept: 0.0,
        }),
        linear_mapping: None,
        optional: true,
        labels: Some(["Monk", "Minimalist", "Average", "Collector", "Hoarder"]),
        probability_to_be_none: P_NONE,
    },
    AdditionalPreference {
        name: "how_much_you_want_to_have_children",
        min: 0,
        max: 5,
        mean: 2.0,
        std_dev: 1.0,
        mean_alteration: MeanAlteration::Set,
        std_dev_alteration: StdDevAlteration::FromMean(Linear {
            slope: 0.1,
            intercept: 0.0,
        }),
        linear_mapping: None,
        optional: true,
        labels: Some([
            "I don't want children",
            "I don't want children now",
            "I might want children",
            "I want children",
            "I want many children",
        ]),
        probability_to_be_none: P_NONE,
    },
    AdditionalPreference {
        name: "how_much_you_want_to_get_married",
        min: 0,
        max: 5,
        mean: 2.0,
        std_dev: 1.0,
        mean_alteration: MeanAlteration::Set,
        std_dev_alteration: StdDevAlteration::FromMean(Linear {
            slope: 0.1,
            intercept: 0.0,
        }),
        linear_mapping: None,
        optional: true,
        labels: Some([
            "I don't want to get married",
            "I don't want to get married now",
            "I might want to get married",
            "I want to get married",
            "I want to get married soon",
        ]),
        probability_to_be_none: P_NONE,
    },
    AdditionalPreference {
        name: "drinks_consumed_per_week",
        min: 0,
        max: 50,
        mean: 5.0,
        std_dev: 5.0,
        mean_alteration: MeanAlteration::Set,
        std_dev_alteration: StdDevAlteration::FromValue(Linear {
            slope: 0.1,
            intercept: 0.0,
        }),
        linear_mapping: None,
        optional: true,
        labels: None,
        probability_to_be_none: P_NONE,
    },
    AdditionalPreference {
        name: "smokes_per_day",
        min: 0,
        max: 50,
        mean: 5.0,
        std_dev: 5.0,
        mean_alteration: MeanAlteration::Set,
        std_dev_alteration: StdDevAlteration::FromValue(Linear {
            slope: 0.1,
            intercept: 0.0,
        }),
        linear_mapping: None,
        optional: true,
        labels: None,
        probability_to_be_none: P_NONE,
    },
    AdditionalPreference {
        name: "marajuana_consumed_per_week_joints",
        min: 0,
        max: 50,
        mean: 2.0,
        std_dev: 2.0,
        mean_alteration: MeanAlteration::Set,
        std_dev_alteration: StdDevAlteration::FromValue(Linear {
            slope: 0.1,
            intercept: 0.0,
        }),
        linear_mapping: None,
        optional: true,
        labels: None,
        probability_to_be_none: P_NONE,
    },
    AdditionalPreference {
        name: "hours_a_day_spent_on_social_media",
        min: 0,
        max: 24,
        mean: 2.0,
        std_dev: 2.0,
        mean_alteration: MeanAlteration::Set,
        std_dev_alteration: StdDevAlteration::FromValue(Linear {
            slope: 0.1,
            intercept: 0.0,
        }),
        linear_mapping: None,
        optional: true,
        labels: None,
        probability_to_be_none: P_NONE,
    },
];

pub const PREFERENCE_CARDINALITY: usize = 28;
