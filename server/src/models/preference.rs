use std::collections::HashSet;

use crate::vec::shared::VectorSearch;
use fake::Dummy;
use paperclip::actix::Apiv2Schema;
use serde::{Deserialize, Serialize};
use validator::Validate;

use crate::{db::DB, vec::shared::Bbox};

use super::{
    shared::UuidModel,
    user::{User, UserPublicFields},
};

#[derive(Debug, Validate, Serialize, Deserialize, Apiv2Schema, Clone, PartialEq, Eq, Dummy)]
pub struct PreferenceRange {
    #[dummy(faker = "-32768")]
    pub min: i16,
    #[dummy(faker = "32767")]
    pub max: i16,
}

impl Default for PreferenceRange {
    fn default() -> Self {
        Self {
            min: -32768,
            max: 32767,
        }
    }
}

#[derive(
    Debug, Validate, Serialize, Deserialize, Apiv2Schema, Clone, PartialEq, Eq, Dummy, Default,
)]
pub struct Preference {
    pub age: PreferenceRange,
    pub percent_male: PreferenceRange,
    pub percent_female: PreferenceRange,
    pub latitude: PreferenceRange,
    pub longitude: PreferenceRange,
}

impl Preference {
    pub fn get_bbox(&self) -> Bbox<PREFERENCE_LENGTH> {
        Bbox {
            min: [
                self.age.min,
                self.percent_female.min,
                self.percent_male.min,
                self.latitude.min,
                self.longitude.min,
            ],
            max: [
                self.age.max,
                self.percent_female.max,
                self.percent_male.max,
                self.latitude.max,
                self.longitude.max,
            ],
        }
    }
}

pub const PREFERENCE_LENGTH: usize = 5;

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
