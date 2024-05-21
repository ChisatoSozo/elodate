use super::super::internal_models::shared::InternalUuid;
use serde::{Deserialize, Serialize};
use std::marker::PhantomData;
use uuid::Uuid;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ApiUuid<ApiModel, InternalModel> {
    pub id: String,
    _marker: PhantomData<ApiModel>,
    _marker2: PhantomData<InternalModel>,
}

impl<ApiModel, InternalModel> PartialEq for ApiUuid<ApiModel, InternalModel> {
    fn eq(&self, other: &Self) -> bool {
        self.id == other.id
    }
}

impl<ApiModel, InternalModel> Eq for ApiUuid<ApiModel, InternalModel> {}
impl<ApiModel, InternalModel> std::hash::Hash for ApiUuid<ApiModel, InternalModel> {
    fn hash<H: std::hash::Hasher>(&self, state: &mut H) {
        self.id.hash(state);
    }
}

impl<ApiModel, InternalModel> ApiUuid<ApiModel, InternalModel> {
    pub fn new() -> Self {
        Self {
            id: Uuid::new_v4().to_string(),
            _marker: PhantomData,
            _marker2: PhantomData,
        }
    }

    pub fn into_internal_uuid(self) -> InternalUuid<InternalModel> {
        InternalUuid {
            id: self.id,
            _marker: PhantomData,
        }
    }
}

impl<ApiModel, InternalModel> From<String> for ApiUuid<ApiModel, InternalModel> {
    fn from(id: String) -> Self {
        Self {
            id,
            _marker: PhantomData,
            _marker2: PhantomData,
        }
    }
}
