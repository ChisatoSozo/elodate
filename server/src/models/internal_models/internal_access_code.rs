use std::error::Error;

use crate::db::DB;

use super::shared::{Bucket, InternalUuid, Save};
use rand::Rng;

#[derive(Debug, rkyv::Archive, rkyv::Serialize, rkyv::Deserialize)]
#[archive(compare(PartialEq), check_bytes)]
pub struct InternalAccessCode {
    pub uuid: InternalUuid<InternalAccessCode>,
    pub code: String,
    pub used: bool,
}

impl InternalAccessCode {
    pub fn gen(_options: &bool) -> InternalAccessCode {
        let letters = (0..8).map(|_| {
            let mut rng = rand::thread_rng();
            rng.gen_range(65..91) as u8 as char
        });
        //xxxx-xxxx
        let letters_vec = letters.collect::<Vec<char>>();
        let (first4, last4) = letters_vec.as_slice().split_at(4);
        let code = format!(
            "{}-{}",
            first4.iter().collect::<String>(),
            last4.iter().collect::<String>()
        );

        InternalAccessCode {
            uuid: InternalUuid::<InternalAccessCode>::new(),
            code: code,
            used: false,
        }
    }
}

impl Bucket for InternalAccessCode {}

impl Save for InternalAccessCode {
    fn save(self, db: &crate::db::DB) -> Result<InternalUuid<InternalAccessCode>, Box<dyn Error>> {
        db.write_index("access_code.code", &self.code, &self.uuid)?;
        self.uuid.write(&self, db)
    }
}

impl DB {
    pub fn get_access_code_by_code(
        &self,
        username: &String,
    ) -> Result<Option<InternalAccessCode>, Box<dyn Error>> {
        let uuid = self.read_index::<InternalAccessCode>("access_code.code", username)?;
        match uuid {
            Some(uuid) => uuid.load(self),
            None => Ok(None),
        }
    }
}
