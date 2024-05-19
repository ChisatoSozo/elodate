use serde::{Deserialize, Serialize};

use super::shared::{Bbox, LabelPairBbox, LabelPairVec, VectorSearch};
use std::{
    collections::HashSet,
    error::Error,
    fs::File,
    io::{BufReader, BufWriter},
};

#[derive(Clone, Serialize, Deserialize)]
pub struct LinearSearch<const N: usize> {
    vecs: Vec<LabelPairVec<N>>,
    bboxes: Vec<LabelPairBbox<N>>,
}

impl<const N: usize> VectorSearch<N> for LinearSearch<N> {
    fn new_vec_store(vecs: Vec<LabelPairVec<N>>) -> Self {
        LinearSearch {
            vecs,
            bboxes: vec![],
        }
    }

    fn new_bbox_store(bboxes: Vec<LabelPairBbox<N>>) -> Self {
        LinearSearch {
            vecs: vec![],
            bboxes,
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
                        // println!(
                        //     "[INV] idx: {}, min: {}, max: {}, loc: {}",
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
                        // println!(
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

    fn add(&mut self, location: &[i16; N], label: &String) {
        self.vecs.push(LabelPairVec {
            label: label.clone(),
            vec: *location,
        });
    }

    fn add_bbox(&mut self, bbox: &Bbox<N>, label: &String) {
        self.bboxes.push(LabelPairBbox {
            label: label.clone(),
            bbox: bbox.clone(),
        });
    }

    fn add_multiple(&mut self, locations: &[[i16; N]], label: &String) {
        for location in locations {
            self.add(location, label);
        }
    }

    fn add_multiple_bboxes(&mut self, bboxes: &[Bbox<N>], label: &String) {
        for bbox in bboxes {
            self.add_bbox(bbox, label);
        }
    }

    fn remove(&mut self, label: &String) {
        self.vecs.retain(|label_pair| label_pair.label != *label);
    }

    fn remove_bbox(&mut self, label: &String) {
        self.bboxes.retain(|label_pair| label_pair.label != *label);
    }

    fn remove_multiple(&mut self, labels: &[String]) {
        for label in labels {
            self.remove(label);
        }
    }

    fn remove_multiple_bboxes(&mut self, labels: &[String]) {
        for label in labels {
            self.remove_bbox(label);
        }
    }

    fn load_from_file(path: &str) -> Result<LinearSearch<N>, Box<dyn Error>> {
        //fild exists?
        if !std::path::Path::new(path).exists() {
            return Ok(LinearSearch {
                vecs: vec![],
                bboxes: vec![],
            });
        }
        let file = File::open(path)?;
        let reader = BufReader::new(file);
        let loaded: LinearSearch<N> = bincode::deserialize_from(reader)?;
        Ok(loaded)
    }

    fn save_to_file(&self, path: &str) -> Result<(), Box<dyn Error>> {
        let file = File::create(path)?;
        let writer = BufWriter::new(file);
        bincode::serialize_into(writer, &self)?;
        Ok(())
    }
}
