use crate::test::fake::Gen;
use crate::vec::shared::VectorSearch;
use std::collections::HashSet;

use super::internal_prefs_config::PREFS_CARDINALITY;
use super::internal_prefs_config::PREFS_CONFIG;
use super::internal_prefs_config::P_NONE;
use super::internal_prefs_config::P_NONE_PROP;
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
    fn get_vector(&self) -> [i16; PREFS_CARDINALITY] {
        let mut vector = [-32768 as i16; PREFS_CARDINALITY];

        for index in 0..PREFS_CARDINALITY {
            if let Some(preference) = self.get(index) {
                vector[index] = preference.value;
            }
        }

        vector
    }
}

impl Gen<'_, Vec<LabeledProperty>> for Vec<LabeledPreferenceRange> {
    fn gen(props: &Vec<LabeledProperty>) -> Self {
        let mut rng = rand::thread_rng();

        let prefs = (0..(PREFS_CARDINALITY))
            .map(|i| {
                let preference = &PREFS_CONFIG[i];
                let range = sample_range_from_preference_and_prop(
                    preference,
                    props.get(i).unwrap().value,
                    &mut rng,
                );
                LabeledPreferenceRange {
                    name: preference.name.to_string(),
                    range,
                }
            })
            .collect();
        prefs
    }
}

impl GetBbox for Vec<LabeledPreferenceRange> {
    fn get_bbox(&self) -> Bbox<PREFS_CARDINALITY> {
        let mut min_vals = [-32768 as i16; PREFS_CARDINALITY];
        let mut max_vals = [32767 as i16; PREFS_CARDINALITY];

        for index in 0..PREFS_CARDINALITY {
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
        props: &Vec<LabeledProperty>,
        seen: &Vec<InternalUuid<InternalUser>>,
    ) -> Result<HashSet<InternalUuid<InternalUser>>, Box<dyn std::error::Error>> {
        let arc_clone = self.vec_index.clone();
        let lock = arc_clone.lock().map_err(|_| "Error getting lock")?;
        let inv = {
            lock.search_inverse(
                &props.get_vector(),
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
        prefs: &Vec<LabeledPreferenceRange>,
        seen: &Vec<InternalUuid<InternalUser>>,
    ) -> Result<HashSet<InternalUuid<InternalUser>>, Box<dyn std::error::Error>> {
        let arc_clone = self.vec_index.clone();
        let lock = arc_clone.lock().map_err(|_| "Error getting lock")?;
        let inv = {
            lock.search(
                &prefs.get_bbox(),
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
        props: &Vec<LabeledProperty>,
        prefs: &Vec<LabeledPreferenceRange>,
        seen: &Vec<InternalUuid<InternalUser>>,
    ) -> Result<Vec<InternalUser>, Box<dyn std::error::Error>> {
        let users_who_prefer_me = self.get_users_who_prefer_me_direct(props, &seen)?;
        let users_who_i_prefer = self.get_users_who_i_prefer_direct(prefs, &seen)?;

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
        props: &Vec<LabeledProperty>,
        preference: &Vec<LabeledPreferenceRange>,
        seen: &Vec<InternalUuid<InternalUser>>,
    ) -> Result<usize, Box<dyn std::error::Error>> {
        let users_who_prefer_me = self.get_users_who_prefer_me_direct(props, &seen)?;
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
        self.get_users_who_prefer_me_direct(&user.props, &user.seen)
    }

    pub fn get_users_who_i_prefer(
        &self,
        user: &InternalUser,
    ) -> Result<HashSet<InternalUuid<InternalUser>>, Box<dyn std::error::Error>> {
        self.get_users_who_i_prefer_direct(&user.prefs, &user.seen)
    }

    pub fn get_mutual_preference_users(
        &self,
        user: &InternalUser,
    ) -> Result<Vec<InternalUser>, Box<dyn std::error::Error>> {
        self.get_mutual_preference_users_direct(&user.props, &user.prefs, &user.seen)
    }

    pub fn get_mutual_preference_users_count(
        &self,
        user: &InternalUser,
    ) -> Result<usize, Box<dyn std::error::Error>> {
        self.get_mutual_preference_users_count_direct(&user.props, &user.prefs, &user.seen)
    }

    pub fn get_users_i_prefer_count(
        &self,
        user: &InternalUser,
    ) -> Result<usize, Box<dyn std::error::Error>> {
        self.get_users_i_prefer_count_direct(&user.prefs, &user.seen)
    }
}

#[derive(Debug, Serialize, Apiv2Schema, Clone, PartialEq)]
pub enum UIElement {
    Slider,
    GenderPicker,
    LocationPicker,
    HeightAndWeight,
    NumberInput,
}

#[derive(Debug, Serialize, Apiv2Schema, Clone, PartialEq)]
pub enum Category {
    Mandatory,
    Financial,
    Physical,
    Future,
    Lgbt,
    Beliefs,
    Background,
    Hobbies,
    Diet,
    Sexual,
    Substances,
    Lifestyle,
    RelationshipStyle,
    Misc,
}

#[derive(Debug, Apiv2Schema, Clone, PartialEq)]
pub struct PreferenceConfig {
    pub name: &'static str,
    pub display: &'static str,
    pub category: Category,
    pub group: &'static str,
    pub ui_element: UIElement,
    pub value_question: &'static str,
    pub range_question: &'static str,
    pub min: i16,
    pub max: i16,
    pub mean: f64,
    pub std_dev: f64,
    pub mean_alteration: MeanAlteration,
    pub std_dev_alteration: StdDevAlteration,
    pub linear_mapping: Option<LinearMapping>,
    pub non_optional_message: Option<&'static str>,
    pub default: Option<i16>,
    pub probability_to_be_none: f64,
    pub labels: Option<&'static [&'static str]>,
}

pub const fn default_preference_config() -> PreferenceConfig {
    PreferenceConfig {
        name: "default",
        display: "default",
        category: Category::Misc,
        group: "default",
        ui_element: UIElement::Slider,
        value_question: "default",
        range_question: "default",
        min: 0,
        max: 4,
        mean: 2.0,
        std_dev: 1.0,
        mean_alteration: MeanAlteration::Set,
        std_dev_alteration: StdDevAlteration::None,
        linear_mapping: None,
        non_optional_message: None,
        default: None,
        probability_to_be_none: P_NONE,
        labels: None,
    }
}

impl PreferenceConfig {
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
            labels: self
                .labels
                .map(|l| l.to_vec().iter().map(|s| s.to_string()).collect()),
            non_optional_message: self.non_optional_message.map(|s| s.to_string()),
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
    pub labels: Option<Vec<String>>,
    pub non_optional_message: Option<String>,
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

impl PreferenceConfig {
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
        props: &Vec<LabeledProperty>,
        rng: &mut ThreadRng,
    ) -> PreferenceRange {
        let prop = props.iter().find(|p| p.name == self.name).unwrap().value;

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
