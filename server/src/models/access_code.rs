use paperclip::actix::Apiv2Schema;
use rand::Rng;
use serde::{Deserialize, Serialize};

// A trait that the Validate derive will impl
use validator::Validate;

use crate::mokuroku::lib::{Document, Emitter, Error};

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

impl Document for AccessCode {
    fn from_bytes(_key: &[u8], value: &[u8]) -> Result<Self, Error> {
        let serde_result: AccessCode =
            serde_cbor::from_slice(value).map_err(|err| Error::Serde(format!("{}", err)))?;
        Ok(serde_result)
    }

    fn to_bytes(&self) -> Result<Vec<u8>, Error> {
        let encoded = serde_cbor::to_vec(self).map_err(|err| Error::Serde(format!("{}", err)))?;
        Ok(encoded)
    }

    fn map(&self, view: &str, emitter: &Emitter) -> Result<(), Error> {
        match view {
            "uuid" => {
                let bytes = self.uuid.0.as_bytes();
                emitter.emit(bytes, None)?;
            }
            "code" => {
                let bytes = self.code.as_bytes();

                emitter.emit(bytes, None)?;
            }
            _ => {}
        };
        Ok(())
    }
}
