use crate::db::DB;
use crate::vec::shared::Bbox;
use rkyv::validation::validators::DefaultValidator;
use rkyv::{Deserialize, Infallible};
use std::error::Error;
use std::marker::PhantomData;
use uuid::Uuid;

use super::internal_prefs_config::PREFS_CARDINALITY;

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
    pub fn load(&self, db: &DB) -> Result<Option<InternalModel>, Box<dyn Error>> {
        let model = db.read_object(&self)?;
        Ok(model)
    }

    pub fn exists(&self, db: &DB) -> Result<bool, Box<dyn Error>> {
        let exists = db.object_exists(&self)?;
        Ok(exists)
    }

    pub fn delete(self, db: &DB) -> Result<Option<InternalModel>, Box<dyn Error>> {
        db.delete_object(&self)
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

pub trait Save: Sized {
    fn save(self, db: &DB) -> Result<InternalUuid<Self>, Box<dyn Error>>;
}

pub trait GetBbox {
    fn get_bbox(&self) -> Bbox<PREFS_CARDINALITY>;
}

pub trait GetVector {
    fn get_vector(&self) -> [i16; PREFS_CARDINALITY];
}
