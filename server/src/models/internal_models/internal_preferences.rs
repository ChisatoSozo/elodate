use crate::test::fake::Gen;
use crate::vec::shared::VectorSearch;
use std::array;
use std::collections::HashSet;

use super::internal_user::InternalUser;
use super::shared::GetBbox;
use super::shared::GetVector;
use super::shared::InternalUuid;
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
pub struct LabeledProperty {
    pub name: String,
    pub value: i16,
}

impl GetVector for Vec<LabeledProperty> {
    fn get_vector(&self) -> [i16; PREFERENCES_CARDINALITY] {
        let mut vector = [-32768 as i16; PREFERENCES_CARDINALITY];

        for index in 0..PREFERENCES_CARDINALITY {
            if let Some(preference) = self.get(index) {
                vector[index] = preference.value;
            }
        }

        vector
    }
}

impl Gen<'_, Vec<LabeledProperty>> for Vec<LabeledPreferenceRange> {
    fn gen(properties: &Vec<LabeledProperty>) -> Self {
        let mut rng = rand::thread_rng();

        let preferences = (0..(PREFERENCES_CARDINALITY))
            .map(|i| {
                let preference = &PREFERENCES_CONFIG[i];
                let range = sample_range_from_preference_and_prop(
                    preference,
                    properties.get(i).unwrap().value,
                    &mut rng,
                );
                LabeledPreferenceRange {
                    name: preference.name.to_string(),
                    range,
                }
            })
            .collect();
        preferences
    }
}

impl GetBbox for Vec<LabeledPreferenceRange> {
    fn get_bbox(&self) -> Bbox<PREFERENCES_CARDINALITY> {
        let mut min_vals = [-32768 as i16; PREFERENCES_CARDINALITY];
        let mut max_vals = [32767 as i16; PREFERENCES_CARDINALITY];

        for index in 0..PREFERENCES_CARDINALITY {
            if let Some(preference) = self.get(index) {
                min_vals[index] = preference.range.min;
                max_vals[index] = preference.range.max;
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
        &self,
        properties: &Vec<LabeledProperty>,
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
        preferences: &Vec<LabeledPreferenceRange>,
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
        properties: &Vec<LabeledProperty>,
        preferences: &Vec<LabeledPreferenceRange>,
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
        properties: &Vec<LabeledProperty>,
        preference: &Vec<LabeledPreferenceRange>,
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
        preference: &Vec<LabeledPreferenceRange>,
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

#[derive(Debug, Serialize, Apiv2Schema, Clone, PartialEq)]
pub enum UIElement {
    Slider,
    GenderPicker,
    LocationPicker,
}

#[derive(Debug, Serialize, Apiv2Schema, Clone, PartialEq)]
pub enum Category {
    Mandatory,
    Financial,
    Physical,
    Future,
    Lgbt,
    Beliefs,
    Hobbies,
    Diet,
    Sexual,
    Substances,
    Lifestyle,
}

#[derive(Debug, Apiv2Schema, Clone, PartialEq)]
pub struct PreferenceConfig<'a> {
    pub name: &'a str,
    pub display: &'a str,
    pub category: Category,
    pub group: &'a str,
    pub ui_element: UIElement,
    pub value_question: &'a str,
    pub range_question: &'a str,
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
            category: self.category.clone(),
            group: self.group.to_string(),
            ui_element: self.ui_element.clone(),
            value_question: self.value_question.to_string(),
            range_question: self.range_question.to_string(),
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

#[derive(Debug, Serialize, Apiv2Schema, Clone, PartialEq)]
pub struct PreferenceConfigPublic {
    pub name: String,
    pub display: String,
    pub category: Category,
    pub group: String,
    pub ui_element: UIElement,
    pub value_question: String,
    pub range_question: String,
    pub min: i16,
    pub max: i16,
    pub linear_mapping: Option<LinearMapping>,
    pub labels: Option<[String; 5]>,
    pub optional: bool,
}

fn f64_to_i16(value: f64, preference: &PreferenceConfig) -> i16 {
    if let Some(linear_mapping) = &preference.linear_mapping {
        let real_min = linear_mapping.real_min;
        let real_max = linear_mapping.real_max;
        let value = (value - real_min) / (real_max - real_min) * 32767.0;
        value as i16
    } else {
        value as i16
    }
}

fn sample_range_from_preference_and_prop(
    preference: &PreferenceConfig,
    prop: i16,
    rng: &mut ThreadRng,
) -> PreferenceRange {
    //get if none
    if rng.gen_range(0.0..1.0) < preference.probability_to_be_none {
        return PreferenceRange {
            min: i16::MIN,
            max: i16::MAX,
        };
    }

    let mut mean = f64_to_i16(preference.mean, preference) as f64;
    let mut std_dev = f64_to_i16(preference.std_dev, preference) as f64;

    match &preference.mean_alteration {
        MeanAlteration::Increase => mean += prop as f64,
        MeanAlteration::Decrease => mean -= prop as f64,
        MeanAlteration::Set => mean = prop as f64,
        MeanAlteration::FromValue(linear) => mean = linear.slope * prop as f64 + linear.intercept,
        _ => (),
    }

    match &preference.std_dev_alteration {
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
    let mut min = preference.max;
    let mut max = preference.min;
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

    if min < preference.min {
        min = preference.min;
    }

    if max > preference.max {
        max = preference.max;
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

    pub fn sample_range(
        &self,
        properties: &Vec<LabeledProperty>,
        rng: &mut ThreadRng,
    ) -> PreferenceRange {
        let prop = properties
            .iter()
            .find(|p| p.name == self.name)
            .unwrap()
            .value;

        sample_range_from_preference_and_prop(self, prop, rng)
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

pub static PREFERENCES_CONFIG: [PreferenceConfig; PREFERENCES_CARDINALITY] = [
    PreferenceConfig {
        name: "age",
        group: "age",
        ui_element: UIElement::Slider,
        display: "Age",
        category: Category::Mandatory,
        value_question: "",
        range_question: "How old do you want your partner to be?",
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
    PreferenceConfig {
        name: "percent_male",
        group: "gender",
        ui_element: UIElement::GenderPicker,
        display: "Percent Male",
        category: Category::Mandatory,
        value_question: "What's your gender?",
        range_question: "What gender are you interested in?",
        min: 0,
        max: 100,
        mean: 50.0,
        std_dev: 1000.0,
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
    PreferenceConfig {
        name: "percent_female",
        group: "gender",
        ui_element: UIElement::GenderPicker,
        display: "Percent Female",
        category: Category::Mandatory,
        value_question: "What's your gender?",
        range_question: "What gender are you interested in?",
        min: 0,
        max: 100,
        mean: 50.0,
        std_dev: 100000.0,
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
    PreferenceConfig {
        name: "latitude",
        group: "location",
        ui_element: UIElement::LocationPicker,
        display: "Latitude",
        category: Category::Mandatory,
        value_question: "Where are ya?",
        range_question: "How far away are you willing to go to meet someone?",
        min: -32767,
        max: 32767,
        mean: 0.0,
        std_dev: 1000000.0,
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
    PreferenceConfig {
        name: "longitude",
        group: "location",
        ui_element: UIElement::LocationPicker,
        display: "Longitude",
        category: Category::Mandatory,
        value_question: "Where are ya?",
        range_question: "How far away are you willing to go to meet someone?",
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
    PreferenceConfig {
        name: "salary_per_year",
        group: "salary_per_year",
        ui_element: UIElement::Slider,
        display: "Salary per Year",
        category: Category::Financial,
        value_question: "How much do you make per year?",
        range_question: "How much do you want your partner to make?",
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
        group: "height_cm",
        ui_element: UIElement::Slider,
        display: "Height (cm)",
        category: Category::Physical,
        value_question: "How tall are you?",
        range_question: "How tall do you want your partner to be?",
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
        group: "bmi",
        ui_element: UIElement::Slider,
        display: "BMI",
        category: Category::Physical,
        value_question: "What's your BMI?",
        range_question: "What BMI do you want your partner to have?",
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
        group: "number_of_times_a_week_you_want_to_have_sex",
        ui_element: UIElement::Slider,
        display: "Number of Times a Week You Want to Have Sex",
        category: Category::Sexual,
        value_question: "How many times a week do you want to have Sex?",
        range_question: "How many times a week do you want your partner to want to have Sex?",
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
        group: "is_trans",
        ui_element: UIElement::Slider,
        display: "Is Transgender",
        category: Category::Lgbt,
        value_question: "Are you trans?",
        range_question: "Do you want your partner to be trans?",
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
        name: "is_queer",
        group: "is_queer",
        ui_element: UIElement::Slider,
        display: "Is Queer",
        category: Category::Lgbt,
        value_question: "Are you queer?",
        range_question: "Do you want your partner to be queer?",
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
        group: "political_affiliation",
        ui_element: UIElement::Slider,
        display: "Political Affiliation",
        category: Category::Beliefs,
        value_question: "What's your political affiliation?",
        range_question: "What political affiliation do you want your partner to have?",
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
        group: "fitness_level",
        ui_element: UIElement::Slider,
        display: "Fitness Level",
        category: Category::Physical,
        value_question: "What's your fitness level?",
        range_question: "What fitness level do you want your partner to have?",
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
        group: "number_of_children",
        ui_element: UIElement::Slider,
        display: "Number of Children You Have",
        category: Category::Lifestyle,
        value_question: "How many children do you have?",
        range_question: "How many children do you want your partner to have?",
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
        group: "number_of_dogs",
        ui_element: UIElement::Slider,
        display: "Number of Dogs You Have",
        category: Category::Lifestyle,
        value_question: "How many dogs do you have?",
        range_question: "How many dogs do you want your partner to have?",
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
        group: "number_of_cats",
        ui_element: UIElement::Slider,
        display: "Number of Cats You Have",
        category: Category::Lifestyle,
        value_question: "How many cats do you have?",
        range_question: "How many cats do you want your partner to have?",
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
        group: "vegetarianness",
        ui_element: UIElement::Slider,
        display: "Vegetarianness",
        category: Category::Diet,
        value_question: "How vegetarian are you?",
        range_question: "How vegetarian do you want your partner to be?",
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
        group: "gamerness_level",
        ui_element: UIElement::Slider,
        display: "Gamerness Level",
        category: Category::Hobbies,
        value_question: "How much of a gamer are you?",
        range_question: "How much of a gamer do you want your partner to be?",
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
        group: "extroversion_level",
        ui_element: UIElement::Slider,
        display: "Extroversion Level",
        category: Category::Lifestyle,
        value_question: "How extroverted are you?",
        range_question: "How extroverted do you want your partner to be?",
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
        group: "how_much_you_want_to_go_outside",
        ui_element: UIElement::Slider,
        display: "How Much You Want to Go Outside",
        category: Category::Hobbies,
        value_question: "How much do you want to go outside?",
        range_question: "How much do you want your partner to want to go outside?",
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
        group: "how_much_you_want_to_travel",
        ui_element: UIElement::Slider,
        display: "How Much You Want to Travel",
        category: Category::Hobbies,
        value_question: "How much do you want to travel?",
        range_question: "How much do you want your partner to want to travel?",
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
        group: "how_cleanly_are_you",
        ui_element: UIElement::Slider,
        display: "How Cleanly Are You",
        category: Category::Lifestyle,
        value_question: "How cleanly are you?",
        range_question: "How cleanly do you want your partner to be?",
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
        group: "hoarder_level",
        ui_element: UIElement::Slider,
        display: "Hoarder Level",
        category: Category::Lifestyle,
        value_question: "How much of a hoarder are you?",
        range_question: "How much of a hoarder do you want your partner to be?",
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
        group: "how_much_you_want_to_have_children",
        ui_element: UIElement::Slider,
        display: "How Much You Want to Have Children",
        category: Category::Future,
        value_question: "How much do you want to have children?",
        range_question: "How much do you want your partner to want to have children?",
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
        group: "how_much_you_want_to_get_married",
        ui_element: UIElement::Slider,
        display: "How Much You Want to Get Married",
        category: Category::Future,
        value_question: "How much do you want to get married?",
        range_question: "How much do you want your partner to want to get married?",
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
        group: "drinks_consumed_per_week",
        ui_element: UIElement::Slider,
        display: "Drinks Consumed per Week",
        category: Category::Substances,
        value_question: "How many drinks do you have a week?",
        range_question: "How many drinks do you want your partner to have a week?",
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
        group: "smokes_per_day",
        ui_element: UIElement::Slider,
        display: "Smokes per Day",
        category: Category::Substances,
        value_question: "How many cigarettes do you smoke a day?",
        range_question: "How many cigarettes do you want your partner to smoke a day?",
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
        group: "marajuana_consumed_per_week_joints",
        ui_element: UIElement::Slider,
        display: "Marijuana Consumed per Week (Joints)",
        category: Category::Substances,
        value_question: "How much weed do you smoke a week, if you were to measure it in joints?",
        range_question: "How much weed do you want your partner to smoke a week, if they were to measure it in joints?",
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
        group: "hours_a_day_spent_on_social_media",
        ui_element: UIElement::Slider,
        display: "Hours a Day Spent on Social Media",
        category: Category::Hobbies,
        value_question: "How many hours a day do you spend on social media?",
        range_question: "How many hours a day do you want your partner to spend on social media?",
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
        group: "pubic_hair_length",
        ui_element: UIElement::Slider,
        display: "Pubic Hair Length",
        category: Category::Sexual,
        value_question: "How long is your pubic hair?",
        range_question: "How long do you want your partner's pubic hair to be?",
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

pub const PREFERENCES_CARDINALITY: usize = 30;
