use serde::{Deserialize, Serialize};

use super::shared::{Bbox, LabelPairBbox, LabelPairVec, VectorSearch};
use std::collections::HashSet;

#[derive(Serialize, Deserialize)]
pub struct LinearSearch<const N: usize> {
    vec_labels: HashSet<String>,
    bbox_labels: HashSet<String>,
    vecs: Vec<LabelPairVec<N>>,
    bboxes: Vec<LabelPairBbox<N>>,
}

impl<const N: usize> VectorSearch<N> for LinearSearch<N> {
    fn new_vec_store(vecs: Vec<LabelPairVec<N>>) -> Self {
        let vec_labels = vecs
            .iter()
            .map(|label_pair| label_pair.label.clone())
            .collect();
        LinearSearch {
            vecs,
            bboxes: vec![],
            vec_labels,
            bbox_labels: HashSet::new(),
        }
    }

    fn new_bbox_store(bboxes: Vec<LabelPairBbox<N>>) -> Self {
        let bbox_labels = bboxes
            .iter()
            .map(|label_pair| label_pair.label.clone())
            .collect();
        LinearSearch {
            vecs: vec![],
            bboxes,
            vec_labels: HashSet::new(),
            bbox_labels,
        }
    }

    fn new() -> Self {
        LinearSearch {
            vecs: vec![],
            bboxes: vec![],
            vec_labels: HashSet::new(),
            bbox_labels: HashSet::new(),
        }
    }

    fn search<'a>(
        &'a self,
        bbox: &'a Bbox<N>,
        skip_labels: Option<&'a HashSet<String>>,
    ) -> impl Iterator<Item = LabelPairVec<N>> + 'a {
        self.vecs
            .iter()
            .filter(move |label_pair| {
                if let Some(skip) = skip_labels {
                    if skip.contains(&label_pair.label) {
                        return false;
                    }
                }
                for i in 0..N {
                    if label_pair.vec[i] < bbox.min[i] || label_pair.vec[i] > bbox.max[i] {
                        // log::info!(
                        //     "[SRCH] idx: {}, min: {}, max: {}, loc: {}",
                        //     i, bbox.min[i], bbox.max[i], label_pair.vec[i]
                        // );
                        return false;
                    }
                }
                true
            })
            .cloned()
    }

    fn search_inverse<'a>(
        &'a self,
        location: &'a [i16; N],
        skip_labels: Option<&'a HashSet<String>>,
    ) -> impl Iterator<Item = LabelPairBbox<N>> + 'a {
        self.bboxes
            .iter()
            .filter(move |label_pair| {
                if let Some(skip) = skip_labels {
                    if skip.contains(&label_pair.label) {
                        return false;
                    }
                }
                for i in 0..N {
                    if label_pair.bbox.min[i] > location[i] || label_pair.bbox.max[i] < location[i]
                    {
                        // log::info!(
                        //     "[INV] idx: {}, min: {}, max: {}, loc: {}",
                        //     i, label_pair.bbox.min[i], label_pair.bbox.max[i], location[i]
                        // );
                        return false;
                    }
                }
                true
            })
            .cloned()
    }

    fn contains_vec(&self, label: &String) -> bool {
        self.vec_labels.contains(label)
    }

    fn contains_bbox(&self, label: &String) -> bool {
        self.bbox_labels.contains(label)
    }

    fn add(&mut self, location: &[i16; N], label: &String) {
        if self.vec_labels.contains(label) {
            //update the vec
            self.vecs
                .iter_mut()
                .find(|label_pair| label_pair.label == *label)
                .map(|label_pair| label_pair.vec = *location);
        } else {
            self.vecs.push(LabelPairVec {
                label: label.clone(),
                vec: *location,
            });
            self.vec_labels.insert(label.clone());
        }
    }

    fn add_bbox(&mut self, bbox: &Bbox<N>, label: &String) {
        if self.bbox_labels.contains(label) {
            //update the bbox
            self.bboxes
                .iter_mut()
                .find(|label_pair| &label_pair.label == label)
                .map(|label_pair| label_pair.bbox = bbox.clone());
        } else {
            self.bboxes.push(LabelPairBbox {
                label: label.clone(),
                bbox: bbox.clone(),
            });
            self.bbox_labels.insert(label.clone());
        }
    }

    fn remove(&mut self, label: &String) {
        self.vecs.retain(|label_pair| label_pair.label != *label);
        self.vec_labels.remove(label);
    }

    fn remove_bbox(&mut self, label: &String) {
        self.bboxes.retain(|label_pair| label_pair.label != *label);
        self.bbox_labels.remove(label);
    }
}
