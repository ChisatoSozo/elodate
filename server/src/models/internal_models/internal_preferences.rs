use crate::vec::shared::VectorSearch;
use std::array;
use std::collections::HashSet;

use super::internal_user::InternalUser;
use super::shared::{Gen, InternalUuid};
use paperclip::actix::Apiv2Schema;
use rand::rngs::ThreadRng;
use rand::Rng;
use rand_distr::Distribution;
use rand_distr::Normal;
use serde::{Deserialize, Serialize};

use crate::{db::DB, vec::shared::Bbox};

#[derive(
    Debug,
    Clone,
    rkyv::Archive,
    rkyv::Serialize,
    rkyv::Deserialize,
    Serialize,
    Deserialize,
    Apiv2Schema,
)]
#[archive(compare(PartialEq), check_bytes)]
pub struct PreferenceRange {
    pub min: i16,
    pub max: i16,
}

#[derive(
    Debug,
    Clone,
    rkyv::Archive,
    rkyv::Serialize,
    rkyv::Deserialize,
    Serialize,
    Deserialize,
    Apiv2Schema,
)]
#[archive(compare(PartialEq), check_bytes)]
pub struct LabeledPreferenceRange {
    pub name: String,
    pub range: PreferenceRange,
}

#[derive(
    Debug,
    Clone,
    rkyv::Archive,
    rkyv::Serialize,
    rkyv::Deserialize,
    Serialize,
    Deserialize,
    Apiv2Schema,
)]
#[archive(compare(PartialEq), check_bytes)]
pub struct Preferences {
    pub age: PreferenceRange,
    pub percent_male: PreferenceRange,
    pub percent_female: PreferenceRange,
    pub latitude: PreferenceRange,
    pub longitude: PreferenceRange,
    pub additional_preferences: Vec<LabeledPreferenceRange>,
}

#[derive(
    Debug,
    Clone,
    rkyv::Archive,
    rkyv::Serialize,
    rkyv::Deserialize,
    Serialize,
    Deserialize,
    Apiv2Schema,
)]
#[archive(compare(PartialEq), check_bytes)]
pub struct LabeledProperty {
    pub name: String,
    pub value: i16,
}

#[derive(
    Debug,
    Clone,
    rkyv::Archive,
    rkyv::Serialize,
    rkyv::Deserialize,
    Serialize,
    Deserialize,
    Apiv2Schema,
)]
#[archive(compare(PartialEq), check_bytes)]
pub struct Properties {
    pub age: i16,
    pub percent_male: i16,
    pub percent_female: i16,
    pub latitude: i16,
    pub longitude: i16,
    pub additional_properties: Vec<LabeledProperty>,
}

impl Properties {
    pub fn get_vector(&self) -> [i16; TOTAL_PREFERENCES_CARDINALITY] {
        let mut vector = [0 as i16; TOTAL_PREFERENCES_CARDINALITY];

        vector[0] = self.age;
        vector[1] = self.percent_male;
        vector[2] = self.percent_female;
        vector[3] = self.latitude;
        vector[4] = self.longitude;

        let mut index = 5; // Start from the 6th element in the array

        while index < TOTAL_PREFERENCES_CARDINALITY {
            if let Some(preference) = self.additional_properties.get(index - 5) {
                vector[index] = preference.value;
            } else {
                vector[index] = -32768;
            }
            index += 1;
        }

        vector
    }
}

impl Gen<Properties> for Preferences {
    fn gen(user: &Properties) -> Self {
        let mut rng = rand::thread_rng();
        let age = sample_range_from_additional_preference_and_prop(
            &MANDATORY_PREFERENCES_CONFIG.age,
            user.age,
            &mut rng,
        );
        let percent_male = sample_range_from_additional_preference_and_prop(
            &MANDATORY_PREFERENCES_CONFIG.percent_male,
            user.percent_male,
            &mut rng,
        );
        let percent_female = sample_range_from_additional_preference_and_prop(
            &MANDATORY_PREFERENCES_CONFIG.percent_female,
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

        let additional_preferences = (0..(ADDITIONAL_PREFERENCE_CARDINALITY))
            .map(|i| {
                let additional_preference = &ADDITIONAL_PREFERENCES_CONFIG[i];
                let range = sample_range_from_additional_preference_and_prop(
                    additional_preference,
                    user.additional_properties.get(i).unwrap().value,
                    &mut rng,
                );
                LabeledPreferenceRange {
                    name: additional_preference.name.to_string(),
                    range,
                }
            })
            .collect();
        Preferences {
            age,
            percent_male,
            percent_female,
            latitude,
            longitude,
            additional_preferences,
        }
    }
}

impl Preferences {
    pub fn get_bbox(&self) -> Bbox<TOTAL_PREFERENCES_CARDINALITY> {
        let mut min_vals = [0 as i16; TOTAL_PREFERENCES_CARDINALITY];
        let mut max_vals = [0 as i16; TOTAL_PREFERENCES_CARDINALITY];

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

        while index < TOTAL_PREFERENCES_CARDINALITY {
            if let Some(preference) = self.additional_preferences.get(index - 5) {
                min_vals[index] = preference.range.min;
                max_vals[index] = preference.range.max;
            } else {
                min_vals[index] = -32768;
                max_vals[index] = 32767;
            }
            index += 1;
        }

        Bbox {
            min: min_vals,
            max: max_vals,
        }
    }
}

impl DB {
    fn get_users_who_prefer_me_direct(
        &self,
        properties: &Properties,
        seen: &Vec<InternalUuid<InternalUser>>,
    ) -> Result<HashSet<InternalUuid<InternalUser>>, Box<dyn std::error::Error>> {
        let arc_clone = self.vec_index.clone();
        let lock = arc_clone.lock().map_err(|_| "Error getting lock")?;
        let inv = {
            lock.search_inverse(
                &properties.get_vector(),
                Some(&seen.iter().map(|u| u.id.clone()).collect()),
            )
            .collect::<Vec<_>>()
        };
        Ok(inv
            .iter()
            .map(|u| u.label.clone())
            .map(|u| u.into())
            .collect())
    }

    fn get_users_who_i_prefer_direct(
        &self,
        preferences: &Preferences,
        seen: &Vec<InternalUuid<InternalUser>>,
    ) -> Result<HashSet<InternalUuid<InternalUser>>, Box<dyn std::error::Error>> {
        let arc_clone = self.vec_index.clone();
        let lock = arc_clone.lock().map_err(|_| "Error getting lock")?;
        let inv = {
            lock.search(
                &preferences.get_bbox(),
                Some(&seen.iter().map(|u| u.id.clone()).collect()),
            )
            .collect::<Vec<_>>()
        };
        Ok(inv
            .iter()
            .map(|u| u.label.clone())
            .map(|u| u.into())
            .collect())
    }

    pub fn get_mutual_preference_users_direct(
        &self,
        properties: &Properties,
        preferences: &Preferences,
        seen: &Vec<InternalUuid<InternalUser>>,
    ) -> Result<Vec<InternalUser>, Box<dyn std::error::Error>> {
        let users_who_prefer_me = self.get_users_who_prefer_me_direct(properties, &seen)?;
        let users_who_i_prefer = self.get_users_who_i_prefer_direct(preferences, &seen)?;

        let user_options = users_who_prefer_me
            .intersection(&users_who_i_prefer)
            .map(|u| u.load(self))
            .collect::<Result<Option<Vec<_>>, _>>()?;

        match user_options {
            Some(users) => Ok(users),
            None => Err("Error getting mutual preference users".into()),
        }
    }

    pub fn get_mutual_preference_users_count_direct(
        &self,
        properties: &Properties,
        preference: &Preferences,
        seen: &Vec<InternalUuid<InternalUser>>,
    ) -> Result<usize, Box<dyn std::error::Error>> {
        let users_who_prefer_me = self.get_users_who_prefer_me_direct(properties, &seen)?;
        let users_who_i_prefer = self.get_users_who_i_prefer_direct(preference, &seen)?;

        Ok(users_who_prefer_me
            .intersection(&users_who_i_prefer)
            .count())
    }

    pub fn get_users_i_prefer_count_direct(
        &self,
        preference: &Preferences,
        seen: &Vec<InternalUuid<InternalUser>>,
    ) -> Result<usize, Box<dyn std::error::Error>> {
        Ok(self.get_users_who_i_prefer_direct(preference, &seen)?.len())
    }

    pub fn get_users_who_prefer_me(
        &self,
        user: &InternalUser,
    ) -> Result<HashSet<InternalUuid<InternalUser>>, Box<dyn std::error::Error>> {
        self.get_users_who_prefer_me_direct(&user.properties, &user.seen)
    }

    pub fn get_users_who_i_prefer(
        &self,
        user: &InternalUser,
    ) -> Result<HashSet<InternalUuid<InternalUser>>, Box<dyn std::error::Error>> {
        self.get_users_who_i_prefer_direct(&user.preferences, &user.seen)
    }

    pub fn get_mutual_preference_users(
        &self,
        user: &InternalUser,
    ) -> Result<Vec<InternalUser>, Box<dyn std::error::Error>> {
        self.get_mutual_preference_users_direct(&user.properties, &user.preferences, &user.seen)
    }

    pub fn get_mutual_preference_users_count(
        &self,
        user: &InternalUser,
    ) -> Result<usize, Box<dyn std::error::Error>> {
        self.get_mutual_preference_users_count_direct(
            &user.properties,
            &user.preferences,
            &user.seen,
        )
    }

    pub fn get_users_i_prefer_count(
        &self,
        user: &InternalUser,
    ) -> Result<usize, Box<dyn std::error::Error>> {
        self.get_users_i_prefer_count_direct(&user.preferences, &user.seen)
    }
}

#[derive(Debug, Serialize, Deserialize, Apiv2Schema, Clone, PartialEq)]
pub struct PreferenceConfig<'a> {
    pub name: &'a str,
    pub display: &'a str,
    pub category: &'a str,
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

impl PreferenceConfig<'_> {
    pub fn get_public(&self) -> PreferenceConfigPublic {
        PreferenceConfigPublic {
            name: self.name.to_string(),
            display: self.display.to_string(),
            category: self.category.to_string(),
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
pub struct PreferenceConfigPublic {
    pub name: String,
    pub display: String,
    pub category: String,
    pub min: i16,
    pub max: i16,
    pub linear_mapping: Option<LinearMapping>,
    pub labels: Option<[String; 5]>,
    pub optional: bool,
}

fn f64_to_i16(value: f64, additional_preference: &PreferenceConfig) -> i16 {
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
    additional_preference: &PreferenceConfig,
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

impl<'a> PreferenceConfig<'a> {
    pub fn sample(&self, rng: &mut ThreadRng) -> i16 {
        //get if none
        if rng.gen_range(0.0..1.0) < P_NONE_PROP {
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

    pub fn sample_range(&self, properties: &Properties, rng: &mut ThreadRng) -> PreferenceRange {
        let prop;

        if self.name == "age" {
            prop = properties.age;
        } else if self.name == "percent_male" {
            prop = properties.percent_male;
        } else if self.name == "percent_female" {
            prop = properties.percent_female;
        } else if self.name == "latitude" {
            prop = properties.latitude;
        } else if self.name == "longitude" {
            prop = properties.longitude;
        } else {
            prop = properties
                .additional_properties
                .iter()
                .find(|p| p.name == self.name)
                .unwrap()
                .value;
        }

        sample_range_from_additional_preference_and_prop(self, prop, rng)
    }
}

#[derive(Debug, Deserialize, Apiv2Schema, Clone, PartialEq)]
pub enum MeanAlteration {
    None,
    Increase,
    Decrease,
    Set,
    FromValue(Linear),
}

impl Serialize for MeanAlteration {
    fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
    where
        S: serde::ser::Serializer,
    {
        serializer.serialize_str("None")
    }
}

impl Default for MeanAlteration {
    fn default() -> Self {
        MeanAlteration::None
    }
}

#[derive(Debug, Serialize, Deserialize, Apiv2Schema, Clone, PartialEq)]
pub struct Linear {
    pub slope: f64,
    pub intercept: f64,
}

#[derive(Debug, Deserialize, Apiv2Schema, Clone, PartialEq)]
pub enum StdDevAlteration {
    None,
    FromMean(Linear),
    FromValue(Linear),
}

impl Serialize for StdDevAlteration {
    fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
    where
        S: serde::ser::Serializer,
    {
        serializer.serialize_str("None")
    }
}

impl Default for StdDevAlteration {
    fn default() -> Self {
        StdDevAlteration::None
    }
}

#[derive(Debug, Serialize, Deserialize, Apiv2Schema, Clone, PartialEq)]
pub struct LinearMapping {
    pub real_min: f64,
    pub real_max: f64,
}

//TODO: on a database of 10000 only 9998 are returned with no preference
const P_NONE: f64 = 1.0;
const P_NONE_PROP: f64 = 0.05;
#[derive(Debug, Serialize, Deserialize, Apiv2Schema, Clone, PartialEq)]
#[serde(bound(deserialize = "'de: 'a"))]
pub struct MandatoryPreferencesConfig<'a> {
    pub age: PreferenceConfig<'a>,
    pub percent_male: PreferenceConfig<'a>,
    pub percent_female: PreferenceConfig<'a>,
    pub latitude: PreferenceConfig<'a>,
    pub longitude: PreferenceConfig<'a>,
}

pub static MANDATORY_PREFERENCES_CONFIG: MandatoryPreferencesConfig = MandatoryPreferencesConfig {
    age: PreferenceConfig {
        name: "age",
        display: "Age",
        category: "mandatory",
        min: 18,
        max: 120,
        mean: 35.0,
        std_dev: 20.0,
        mean_alteration: MeanAlteration::Set,
        std_dev_alteration: StdDevAlteration::FromMean(Linear {
            slope: 1.0,
            intercept: 0.0,
        }),
        linear_mapping: None,
        optional: false,
        labels: None,
        probability_to_be_none: 0.0,
    },
    percent_male: PreferenceConfig {
        name: "percent_male",
        display: "Percent Male",
        category: "mandatory",
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
    percent_female: PreferenceConfig {
        name: "percent_female",
        display: "Percent Female",
        category: "mandatory",
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
    latitude: PreferenceConfig {
        name: "latitude",
        display: "Latitude",
        category: "mandatory",
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
    longitude: PreferenceConfig {
        name: "longitude",
        display: "Longitude",
        category: "mandatory",
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
};

const MANDATORY_PREFERENCES_CARDINALITY: usize = 5;

pub static ADDITIONAL_PREFERENCES_CONFIG: [PreferenceConfig; ADDITIONAL_PREFERENCE_CARDINALITY] = [
    PreferenceConfig {
        name: "salary_per_year",
        display: "Salary per Year",
        category: "financial",
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
    PreferenceConfig {
        name: "height_cm",
        display: "Height (cm)",
        category: "physical",
        min: 0,
        max: 250,
        mean: 175.0,
        std_dev: 10.0,
        mean_alteration: MeanAlteration::Set,
        std_dev_alteration: StdDevAlteration::FromMean(Linear {
            slope: 1.0,
            intercept: 0.0,
        }),
        linear_mapping: None,
        optional: true,
        labels: None,
        probability_to_be_none: P_NONE,
    },
    PreferenceConfig {
        name: "bmi",
        display: "BMI",
        category: "physical",
        min: 0,
        max: 100,
        mean: 25.0,
        std_dev: 5.0,
        mean_alteration: MeanAlteration::Set,
        std_dev_alteration: StdDevAlteration::FromMean(Linear {
            slope: 1.0,
            intercept: 0.0,
        }),
        linear_mapping: None,
        optional: true,
        labels: None,
        probability_to_be_none: P_NONE,
    },
    PreferenceConfig {
        name: "number_of_times_a_week_you_want_to_have_sex",
        display: "Number of Times a Week You Want to Have Sex",
        category: "personal",
        min: 0,
        max: 100,
        mean: 2.0,
        std_dev: 2.0,
        mean_alteration: MeanAlteration::Set,
        std_dev_alteration: StdDevAlteration::None,
        linear_mapping: None,
        optional: true,
        labels: None,
        probability_to_be_none: P_NONE,
    },
    PreferenceConfig {
        name: "is_trans",
        display: "Is Transgender",
        category: "personal",
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
    PreferenceConfig {
        name: "political_affiliation",
        display: "Political Affiliation",
        category: "beliefs",
        min: 0,
        max: 4,
        mean: 2.0,
        std_dev: 1.0,
        mean_alteration: MeanAlteration::Set,
        std_dev_alteration: StdDevAlteration::None,
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
    PreferenceConfig {
        name: "fitness_level",
        display: "Fitness Level",
        category: "physical",
        min: 0,
        max: 4,
        mean: 2.0,
        std_dev: 1.0,
        mean_alteration: MeanAlteration::Set,
        std_dev_alteration: StdDevAlteration::None,
        linear_mapping: None,
        optional: true,
        labels: Some(["Couch potato", "Sedentary", "Average", "Fit", "Athlete"]),
        probability_to_be_none: P_NONE,
    },
    PreferenceConfig {
        name: "number_of_children",
        display: "Number of Children You Have",
        category: "personal",
        min: 0,
        max: 10,
        mean: 1.0,
        std_dev: 1.0,
        mean_alteration: MeanAlteration::Set,
        std_dev_alteration: StdDevAlteration::None,
        linear_mapping: None,
        optional: true,
        labels: None,
        probability_to_be_none: P_NONE,
    },
    PreferenceConfig {
        name: "number_of_dogs",
        display: "Number of Dogs You Have",
        category: "personal",
        min: 0,
        max: 10,
        mean: 0.0,
        std_dev: 1.0,
        mean_alteration: MeanAlteration::Set,
        std_dev_alteration: StdDevAlteration::None,
        linear_mapping: None,
        optional: true,
        labels: None,
        probability_to_be_none: P_NONE,
    },
    PreferenceConfig {
        name: "number_of_cats",
        display: "Number of Cats You Have",
        category: "personal",
        min: 0,
        max: 10,
        mean: 0.0,
        std_dev: 1.0,
        mean_alteration: MeanAlteration::Set,
        std_dev_alteration: StdDevAlteration::None,
        linear_mapping: None,
        optional: true,
        labels: None,
        probability_to_be_none: P_NONE,
    },
    PreferenceConfig {
        name: "vegetarianness",
        display: "Vegetarianness",
        category: "diet",
        min: 0,
        max: 4,
        mean: 2.0,
        std_dev: 1.0,
        mean_alteration: MeanAlteration::Set,
        std_dev_alteration: StdDevAlteration::None,
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
    PreferenceConfig {
        name: "gamerness_level",
        display: "Gamerness Level",
        category: "hobbies",
        min: 0,
        max: 4,
        mean: 2.0,
        std_dev: 1.0,
        mean_alteration: MeanAlteration::Set,
        std_dev_alteration: StdDevAlteration::None,
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
    PreferenceConfig {
        name: "extroversion_level",
        display: "Extroversion Level",
        category: "personality",
        min: 0,
        max: 4,
        mean: 2.0,
        std_dev: 1.0,
        mean_alteration: MeanAlteration::Set,
        std_dev_alteration: StdDevAlteration::None,
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
    PreferenceConfig {
        name: "how_much_you_want_to_go_outside",
        display: "How Much You Want to Go Outside",
        category: "hobbies",
        min: 0,
        max: 4,
        mean: 2.0,
        std_dev: 1.0,
        mean_alteration: MeanAlteration::Set,
        std_dev_alteration: StdDevAlteration::None,
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
    PreferenceConfig {
        name: "how_much_you_want_to_travel",
        display: "How Much You Want to Travel",
        category: "hobbies",
        min: 0,
        max: 4,
        mean: 2.0,
        std_dev: 1.0,
        mean_alteration: MeanAlteration::Set,
        std_dev_alteration: StdDevAlteration::None,
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
    PreferenceConfig {
        name: "how_cleanly_are_you",
        display: "How Cleanly Are You",
        category: "personality",
        min: 0,
        max: 4,
        mean: 2.0,
        std_dev: 1.0,
        mean_alteration: MeanAlteration::Set,
        std_dev_alteration: StdDevAlteration::None,
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
    PreferenceConfig {
        name: "hoarder_level",
        display: "Hoarder Level",
        category: "personality",
        min: 0,
        max: 4,
        mean: 2.0,
        std_dev: 1.0,
        mean_alteration: MeanAlteration::Set,
        std_dev_alteration: StdDevAlteration::None,
        linear_mapping: None,
        optional: true,
        labels: Some(["Monk", "Minimalist", "Average", "Collector", "Hoarder"]),
        probability_to_be_none: P_NONE,
    },
    PreferenceConfig {
        name: "how_much_you_want_to_have_children",
        display: "How Much You Want to Have Children",
        category: "personal",
        min: 0,
        max: 4,
        mean: 2.0,
        std_dev: 1.0,
        mean_alteration: MeanAlteration::Set,
        std_dev_alteration: StdDevAlteration::None,
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
    PreferenceConfig {
        name: "how_much_you_want_to_get_married",
        display: "How Much You Want to Get Married",
        category: "personal",
        min: 0,
        max: 4,
        mean: 2.0,
        std_dev: 1.0,
        mean_alteration: MeanAlteration::Set,
        std_dev_alteration: StdDevAlteration::None,
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
    PreferenceConfig {
        name: "drinks_consumed_per_week",
        display: "Drinks Consumed per Week",
        category: "diet",
        min: 0,
        max: 50,
        mean: 5.0,
        std_dev: 5.0,
        mean_alteration: MeanAlteration::Set,
        std_dev_alteration: StdDevAlteration::FromValue(Linear {
            slope: 1.0,
            intercept: 0.0,
        }),
        linear_mapping: None,
        optional: true,
        labels: None,
        probability_to_be_none: P_NONE,
    },
    PreferenceConfig {
        name: "smokes_per_day",
        display: "Smokes per Day",
        category: "diet",
        min: 0,
        max: 50,
        mean: 2.0,
        std_dev: 5.0,
        mean_alteration: MeanAlteration::Set,
        std_dev_alteration: StdDevAlteration::FromValue(Linear {
            slope: 1.0,
            intercept: 0.0,
        }),
        linear_mapping: None,
        optional: true,
        labels: None,
        probability_to_be_none: P_NONE,
    },
    PreferenceConfig {
        name: "marajuana_consumed_per_week_joints",
        display: "Marijuana Consumed per Week (Joints)",
        category: "diet",
        min: 0,
        max: 50,
        mean: 2.0,
        std_dev: 2.0,
        mean_alteration: MeanAlteration::Set,
        std_dev_alteration: StdDevAlteration::FromValue(Linear {
            slope: 1.0,
            intercept: 0.0,
        }),
        linear_mapping: None,
        optional: true,
        labels: None,
        probability_to_be_none: P_NONE,
    },
    PreferenceConfig {
        name: "hours_a_day_spent_on_social_media",
        display: "Hours a Day Spent on Social Media",
        category: "personal",
        min: 0,
        max: 24,
        mean: 2.0,
        std_dev: 2.0,
        mean_alteration: MeanAlteration::Set,
        std_dev_alteration: StdDevAlteration::FromValue(Linear {
            slope: 1.0,
            intercept: 0.0,
        }),
        linear_mapping: None,
        optional: true,
        labels: None,
        probability_to_be_none: P_NONE,
    },
    PreferenceConfig {
        name: "pubic_hair_length",
        display: "Pubic Hair Length",
        category: "physical",
        min: 0,
        max: 4,
        mean: 2.0,
        std_dev: 1.0,
        mean_alteration: MeanAlteration::Set,
        std_dev_alteration: StdDevAlteration::None,
        linear_mapping: None,
        optional: true,
        labels: Some(["Shaved", "Trimmed", "Average", "Bushy", "Jungle"]),
        probability_to_be_none: P_NONE,
    },
];

#[derive(Debug, Serialize, Deserialize, Apiv2Schema, Clone, PartialEq)]
#[serde(bound(deserialize = "'de: 'a"))]
pub struct PreferencesConfig<'a> {
    pub mandatory: MandatoryPreferencesConfig<'a>,
    pub additional: Vec<PreferenceConfig<'a>>,
}

pub fn preferences_config() -> PreferencesConfig<'static> {
    PreferencesConfig {
        mandatory: MANDATORY_PREFERENCES_CONFIG.clone(),
        additional: ADDITIONAL_PREFERENCES_CONFIG.iter().cloned().collect(),
    }
}

pub const ADDITIONAL_PREFERENCE_CARDINALITY: usize = 24;

pub const TOTAL_PREFERENCES_CARDINALITY: usize =
    MANDATORY_PREFERENCES_CARDINALITY + ADDITIONAL_PREFERENCE_CARDINALITY;
