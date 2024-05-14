pub struct LabelPair<T, V> {
    label: T,
    vec: V,
}

pub struct Bbox {
    min: Vec<u16>,
    max: Vec<u16>,
}

trait VectorSearch<T> {
    fn search(&self, bbox: Bbox) -> Vec<Vec<u16>>;
    fn search_inverse(&self, location: &Vec<u16>) -> Vec<Vec<u16>>;
    fn add(&mut self, location: &Vec<u16>, label: &T);
    fn add_bbox(&mut self, bbox: Bbox, label: &T);
    fn add_multiple(&mut self, locations: &Vec<Vec<u16>>, label: &T);
    fn add_multiple_bboxes(&mut self, bboxes: &Vec<Bbox>, label: &T);
    fn remove(&mut self, label: &T);
    fn remove_bbox(&mut self, label: &T);
    fn remove_multiple(&mut self, labels: &Vec<T>);
    fn remove_multiple_bboxes(&mut self, labels: &Vec<T>);
}

pub struct LinearSearch {
    vecs: Vec<LabelPair<String, Vec<u16>>>,
    bboxes: Vec<LabelPair<String, Bbox>>,
}

impl VectorSearch<String> for LinearSearch {
    fn search(&self, bbox: Bbox) -> Vec<Vec<u16>> {
        let mut vecs = vec![];
        for label_pair in &self.vecs {
            if label_pair.vec >= bbox.min && label_pair.vec <= bbox.max {
                vecs.push(label_pair.vec.clone());
            }
        }
        vecs
    }

    fn search_inverse(&self, location: &Vec<u16>) -> Vec<Vec<u16>> {
        let mut vecs = vec![];
        for label_pair in &self.vecs {
            if label_pair.vec != *location {
                vecs.push(label_pair.vec.clone());
            }
        }
        vecs
    }

    fn add(&mut self, location: &Vec<u16>, label: &String) {
        self.vecs.push(LabelPair {
            label: label.clone(),
            vec: location.clone(),
        });
    }

    fn add_bbox(&mut self, bbox: Bbox, label: &String) {
        self.bboxes.push(LabelPair {
            label: label.clone(),
            vec: bbox,
        });
    }

    fn add_multiple(&mut self, locations: &Vec<Vec<u16>>, label: &String) {
        for location in locations {
            self.add(location, label);
        }
    }

    fn add_multiple_bboxes(&mut self, bboxes: &Vec<Bbox>, label: &String) {
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

    fn remove_multiple(&mut self, labels: &Vec<String>) {
        for label in labels {
            self.remove(label);
        }
    }

    fn remove_multiple_bboxes(&mut self, labels: &Vec<String>) {
        for label in labels {
            self.remove_bbox(label);
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn make_n_k_dimensional_vecs_u16_with_labels(
        n: usize,
        k: usize,
    ) -> Vec<LabelPair<String, Vec<u16>>> {
        let mut vecs = vec![];
        for i in 0..n {
            let mut vec = vec![];
            for j in 0..k {
                vec.push(rand::random::<u16>());
            }
            vecs.push(LabelPair {
                label: i.to_string(),
                vec,
            });
        }
        vecs
    }

    fn make_n_k_dimensional_bboxes_u16_with_labels(
        n: usize,
        k: usize,
    ) -> Vec<LabelPair<String, Bbox>> {
        let mut bboxes = vec![];
        for i in 0..n {
            let mut min = vec![];
            let mut max = vec![];
            for j in 0..k {
                min.push(rand::random::<u16>());
                max.push(rand::random::<u16>());
            }
            bboxes.push(LabelPair {
                label: i.to_string(),
                vec: Bbox { min, max },
            });
        }
        bboxes
    }

    #[test]
    fn linear_speed_test_vecs() {
        let mut linear_search = LinearSearch {
            vecs: make_n_k_dimensional_vecs_u16_with_labels(1000, 100),
            bboxes: vec![],
        };
        let bbox = Bbox {
            min: vec![0; 100],
            max: vec![100; 100],
        };
        let start = std::time::Instant::now();
        let vecs = linear_search.search(bbox);
        let duration = start.elapsed();
        println!("Linear search took {:?}", duration);
        assert_eq!(vecs.len(), 1000);
    }

    #[test]
    fn linear_speed_test_bboxes() {
        let mut linear_search = LinearSearch {
            vecs: vec![],
            bboxes: make_n_k_dimensional_bboxes_u16_with_labels(1000, 100),
        };
        let bbox = Bbox {
            min: vec![0; 100],
            max: vec![100; 100],
        };
        let start = std::time::Instant::now();
        let vecs = linear_search.search(bbox);
        let duration = start.elapsed();
        println!("Linear search took {:?}", duration);
        assert_eq!(vecs.len(), 1000);
    }
}
