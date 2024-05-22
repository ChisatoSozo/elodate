use super::super::internal_models::shared::InternalUuid;

use paperclip::v2::schema::TypedData;
use serde::{Deserialize, Serialize};
use std::marker::PhantomData;
use uuid::Uuid;

#[derive(Debug, Clone)]
pub struct ApiUuid<InternalModel> {
    pub id: String,
    _marker: PhantomData<InternalModel>,
}

impl<InternalModel> Serialize for ApiUuid<InternalModel> {
    fn serialize<S: serde::Serializer>(&self, serializer: S) -> Result<S::Ok, S::Error> {
        self.id.serialize(serializer)
    }
}

impl<'de, InternalModel> Deserialize<'de> for ApiUuid<InternalModel> {
    fn deserialize<D: serde::Deserializer<'de>>(deserializer: D) -> Result<Self, D::Error> {
        let id = String::deserialize(deserializer)?;
        Ok(Self {
            id,
            _marker: PhantomData,
        })
    }
}

impl<InternalModel> TypedData for ApiUuid<InternalModel> {
    fn data_type() -> paperclip::v2::models::DataType {
        <String as TypedData>::data_type()
    }

    fn format() -> Option<paperclip::v2::models::DataTypeFormat> {
        <String as TypedData>::format()
    }
}

impl<InternalModel> PartialEq for ApiUuid<InternalModel> {
    fn eq(&self, other: &Self) -> bool {
        self.id == other.id
    }
}

impl<InternalModel> Eq for ApiUuid<InternalModel> {}
impl<InternalModel> std::hash::Hash for ApiUuid<InternalModel> {
    fn hash<H: std::hash::Hasher>(&self, state: &mut H) {
        self.id.hash(state);
    }
}

impl<InternalModel> ApiUuid<InternalModel> {
    pub fn new() -> Self {
        Self {
            id: Uuid::new_v4().to_string(),
            _marker: PhantomData,
        }
    }
}

impl<InternalModel> From<InternalUuid<InternalModel>> for ApiUuid<InternalModel> {
    fn from(uuid: InternalUuid<InternalModel>) -> Self {
        Self {
            id: uuid.id,
            _marker: PhantomData,
        }
    }
}

impl<InternalModel> Into<InternalUuid<InternalModel>> for ApiUuid<InternalModel> {
    fn into(self) -> InternalUuid<InternalModel> {
        InternalUuid {
            id: self.id,
            _marker: PhantomData,
        }
    }
}
