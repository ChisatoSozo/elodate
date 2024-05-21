use crate::db::DB;
use rkyv::validation::validators::DefaultValidator;
use rkyv::{Deserialize, Infallible};
use std::error::Error;
use std::marker::PhantomData;
use uuid::Uuid;

pub trait Gen<T> {
    fn gen(arg: &T) -> Self;
}

#[derive(Debug, Clone, rkyv::Archive, rkyv::Serialize, rkyv::Deserialize)]
#[archive(compare(PartialEq), check_bytes)]
pub struct InternalUuid<InternalModel> {
    pub id: String,
    pub _marker: PhantomData<InternalModel>,
}

impl<InternalModel> PartialEq for InternalUuid<InternalModel> {
    fn eq(&self, other: &Self) -> bool {
        self.id == other.id
    }
}

impl<InternalModel> Eq for InternalUuid<InternalModel> {}
impl<InternalModel> std::hash::Hash for InternalUuid<InternalModel> {
    fn hash<H: std::hash::Hasher>(&self, state: &mut H) {
        self.id.hash(state);
    }
}

impl<InternalModel> InternalUuid<InternalModel>
where
    InternalModel: rkyv::Archive,
    for<'a> InternalModel::Archived:
        rkyv::CheckBytes<DefaultValidator<'a>> + Deserialize<InternalModel, Infallible>,
{
    pub fn load(&self, db: &mut DB) -> Result<Option<InternalModel>, Box<dyn Error>> {
        let chat = db.read_object(&self)?;
        Ok(chat)
    }
}

impl<InternalModel> InternalUuid<InternalModel> {
    pub fn new() -> Self {
        Self {
            id: Uuid::new_v4().to_string(),
            _marker: PhantomData,
        }
    }
}

impl<T> From<String> for InternalUuid<T> {
    fn from(id: String) -> Self {
        Self {
            id,
            _marker: PhantomData,
        }
    }
}

pub trait Save {
    fn save(self, db: &mut DB) -> Result<(), Box<dyn Error>>;
}
