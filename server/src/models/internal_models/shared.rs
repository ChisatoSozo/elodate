use crate::db::{DB, SCRATCH_SPACE_SIZE};
use crate::vec::shared::Bbox;
use rkyv::ser::serializers::{
    AlignedSerializer, AllocScratch, CompositeSerializer, FallbackScratch, HeapScratch,
    SharedSerializeMap,
};
use rkyv::validation::validators::DefaultValidator;
use rkyv::{AlignedVec, Deserialize, Infallible, Serialize};
use std::error::Error;
use std::marker::PhantomData;
use uuid::Uuid;

use super::internal_prefs_config::PREFS_CARDINALITY;

#[derive(Debug, rkyv::Archive, rkyv::Serialize, rkyv::Deserialize)]
#[archive(compare(PartialEq), check_bytes)]
pub struct InternalUuid<InternalModel> {
    pub id: String,
    pub _marker: PhantomData<InternalModel>,
}

impl<InternalModel> Clone for InternalUuid<InternalModel> {
    fn clone(&self) -> Self {
        Self {
            id: self.id.clone(),
            _marker: PhantomData,
        }
    }
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

impl<InternalModel: Bucket> InternalUuid<InternalModel>
where
    InternalModel: rkyv::Archive
        + Serialize<
            CompositeSerializer<
                AlignedSerializer<AlignedVec>,
                FallbackScratch<HeapScratch<SCRATCH_SPACE_SIZE>, AllocScratch>,
                SharedSerializeMap,
            >,
        >,
    for<'a> InternalModel::Archived:
        rkyv::CheckBytes<DefaultValidator<'a>> + Deserialize<InternalModel, Infallible>,
{
    pub fn write(
        &self,
        model: &InternalModel,
        db: &DB,
    ) -> Result<InternalUuid<InternalModel>, Box<dyn Error>> {
        db.write_object(&self, model)
    }

    pub fn load(&self, db: &DB) -> Result<Option<InternalModel>, Box<dyn Error>> {
        let model = db.read_object(InternalModel::bucket(), &self)?;
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

pub trait Bucket {
    fn bucket() -> &'static str {
        //match the type of the object that implements this trait
        let type_name = std::any::type_name::<Self>().split("::").last().unwrap();
        match type_name {
            "InternalChat" => "chat",
            "InternalImage" => "image",
            "InternalUser" => "user",
            "InternalMessage" => "message",
            "InternalAccessCode" => "access_code",
            _ => panic!("Unknown bucket"),
        }
    }
}
