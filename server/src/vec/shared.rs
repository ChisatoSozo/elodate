use std::collections::HashSet;
use std::hash::Hash;
use std::hash::Hasher;

use serde::Deserialize;
use serde::Serialize;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LabelPairVec<const N: usize> {
    pub label: String,
    #[serde(
        serialize_with = "array_helpers::serialize",
        deserialize_with = "array_helpers::deserialize"
    )]
    pub vec: [i16; N],
}

impl<const N: usize> PartialEq for LabelPairVec<N> {
    fn eq(&self, other: &Self) -> bool {
        self.label == other.label && self.vec[0] == other.vec[0] && self.vec[1] == other.vec[1]
    }
}

impl<const N: usize> Eq for LabelPairVec<N> {}

impl<const N: usize> Hash for LabelPairVec<N> {
    fn hash<H: Hasher>(&self, state: &mut H) {
        self.label.hash(state);
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LabelPairBbox<const N: usize> {
    pub label: String,
    pub bbox: Bbox<N>,
}

impl<const N: usize> PartialEq for LabelPairBbox<N> {
    fn eq(&self, other: &Self) -> bool {
        self.label == other.label && self.bbox == other.bbox
    }
}

impl<const N: usize> Eq for LabelPairBbox<N> {}

impl<const N: usize> Hash for LabelPairBbox<N> {
    fn hash<H: Hasher>(&self, state: &mut H) {
        self.label.hash(state);
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Bbox<const N: usize> {
    #[serde(
        serialize_with = "array_helpers::serialize",
        deserialize_with = "array_helpers::deserialize"
    )]
    pub min: [i16; N],
    #[serde(
        serialize_with = "array_helpers::serialize",
        deserialize_with = "array_helpers::deserialize"
    )]
    pub max: [i16; N],
}

impl<const N: usize> PartialEq for Bbox<N> {
    fn eq(&self, other: &Self) -> bool {
        for i in 0..N {
            if self.min[i] != other.min[i] || self.max[i] != other.max[i] {
                return false;
            }
        }
        true
    }
}

impl<const N: usize> Eq for Bbox<N> {}
impl<const N: usize> Hash for Bbox<N> {
    fn hash<H: Hasher>(&self, state: &mut H) {
        for i in 0..N {
            self.min[i].hash(state);
            self.max[i].hash(state);
        }
    }
}
pub trait VectorSearch<const N: usize> {
    fn new() -> Self;
    fn new_vec_store(vecs: Vec<LabelPairVec<N>>) -> Self;
    fn new_bbox_store(bboxes: Vec<LabelPairBbox<N>>) -> Self;
    fn search<'a>(
        &'a self,
        bbox: &'a Bbox<N>,
        skip_labels: Option<&'a HashSet<String>>,
    ) -> impl Iterator<Item = LabelPairVec<N>> + 'a;
    fn search_inverse<'a>(
        &'a self,
        location: &'a [i16; N],
        skip_labels: Option<&'a HashSet<String>>,
    ) -> impl Iterator<Item = LabelPairBbox<N>> + 'a;
    fn contains_vec(&self, label: &String) -> bool;
    fn contains_bbox(&self, label: &String) -> bool;
    fn add(&mut self, location: &[i16; N], label: &String);
    fn add_bbox(&mut self, bbox: &Bbox<N>, label: &String);
    fn remove(&mut self, label: &String);
    fn remove_bbox(&mut self, label: &String);
}

mod array_helpers {
    use serde::{Deserialize, Deserializer, Serialize, Serializer};

    pub fn serialize<S, T, const N: usize>(data: &[T; N], serializer: S) -> Result<S::Ok, S::Error>
    where
        S: Serializer,
        T: Serialize,
    {
        data.as_slice().serialize(serializer)
    }

    pub fn deserialize<'de, D, T, const N: usize>(deserializer: D) -> Result<[T; N], D::Error>
    where
        D: Deserializer<'de>,
        T: Deserialize<'de> + Default + Copy,
    {
        let vec = Vec::<T>::deserialize(deserializer)?;
        if vec.len() == N {
            let mut array = [T::default(); N];
            array.copy_from_slice(&vec);
            Ok(array)
        } else {
            Err(serde::de::Error::invalid_length(
                vec.len(),
                &"expected an array of length N",
            ))
        }
    }
}
