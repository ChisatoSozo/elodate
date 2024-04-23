use paperclip::actix::Apiv2Schema;
use rand::{distributions::Alphanumeric, Rng};
use serde::{Deserialize, Serialize};

// A trait that the Validate derive will impl
use validator::Validate;

use super::shared::UuidModel;

#[derive(Debug, Validate, Serialize, Deserialize, Apiv2Schema, Clone)]
pub struct AccessCode {
    pub uuid: UuidModel,
    pub code: String,
    pub used: bool,
}

impl AccessCode {
    pub fn random_access_code() -> AccessCode {
        let letters = (0..8).map(|_| {
            let mut rng = rand::thread_rng();
            rng.gen_range(65..91) as u8 as char
        });

        AccessCode {
            uuid: UuidModel::new(),
            code: letters.collect::<String>(),
            used: false,
        }
    }
}
