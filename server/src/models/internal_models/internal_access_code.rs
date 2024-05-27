use super::shared::InternalUuid;
use rand::Rng;

#[derive(Debug, Clone, rkyv::Archive, rkyv::Serialize, rkyv::Deserialize)]
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

        InternalAccessCode {
            uuid: InternalUuid::<InternalAccessCode>::new(),
            code: letters.collect::<String>(),
            used: false,
        }
    }
}
