#[test]
fn run_test_suite() {
    use rand::rngs::ThreadRng;
    use rand::Rng;
    use std::collections::HashSet;

    use crate::vec::{
        search_linear::LinearSearch,
        shared::{Bbox, LabelPairBbox, LabelPairVec},
    };

    const CARDINALITIES: [usize; 1] = [1000000];

    use crate::vec::shared::VectorSearch;

    fn make_n_k_dimensional_vecs_i16_with_labels<const N: usize>(
        n: usize,
        rng: &mut ThreadRng,
    ) -> Vec<LabelPairVec<N>> {
        let mut vecs = Vec::with_capacity(n);
        for i in 0..n {
            let mut vec = [0; N];
            for elem in &mut vec {
                *elem = rng.gen::<i16>();
            }
            vecs.push(LabelPairVec {
                label: i.to_string(),
                vec,
            });
        }
        vecs
    }

    fn make_n_k_dimensional_bboxes_i16_with_labels<const N: usize>(
        n: usize,
        rng: &mut ThreadRng,
    ) -> Vec<LabelPairBbox<N>> {
        let mut bboxes = Vec::with_capacity(n);
        for i in 0..n {
            let mut min = [0; N];
            let mut max = [0; N];
            for elem in &mut min {
                *elem = rng.gen::<i16>();
            }
            for elem in &mut max {
                *elem = rng.gen::<i16>();
            }

            // Ensure min is less than max
            for i in 0..N {
                if min[i] > max[i] {
                    let temp = min[i];
                    min[i] = max[i];
                    max[i] = temp;
                }
                let ignored = rng.gen_range(0..(N as u32)) >= 10;

                //if ignored, set min to i16::MIN and max to i16::MAX
                if ignored {
                    min[i] = i16::MIN;
                    max[i] = i16::MAX;
                }
            }

            bboxes.push(LabelPairBbox {
                label: i.to_string(),
                bbox: Bbox { min, max },
            });
        }
        bboxes
    }

    fn run_search_tests<const N: usize, VS: VectorSearch<N>>(
        vecs: &Vec<LabelPairVec<N>>,
        bboxes: &Vec<LabelPairBbox<N>>,
        search_type: &str,
    ) -> (HashSet<[i16; N]>, HashSet<Bbox<N>>) {
        let start_construct_search_vec = std::time::Instant::now();
        let search_vec = VS::new_vec_store(vecs.clone());
        let duration_construct_search_vec = start_construct_search_vec.elapsed();

        let start_construct_search_bbox = std::time::Instant::now();
        let search_bbox = VS::new_bbox_store(bboxes.clone());
        let duration_construct_search_bbox = start_construct_search_bbox.elapsed();

        let start_search = std::time::Instant::now();
        let first_bbox = &bboxes[0].bbox;
        let search_vec_result: Vec<_> = search_vec.search(first_bbox, None).collect();
        let duration_search = start_search.elapsed();

        let start_search_inverse = std::time::Instant::now();
        let first_vec = &vecs[0].vec;
        let search_bbox_result: Vec<_> = search_bbox.search_inverse(first_vec, None).collect();
        let duration_search_inverse = start_search_inverse.elapsed();

        log::info!(
            "------{} Search Test Results for DIM = {}, N = {}------\nVecs: {}\nConstruct: {:?}\nSearch: {:?}\n\nBboxes: {}\nConstruct: {:?}\nSearch: {:?}\n",
            search_type,
            N,
            vecs.len(),
            search_vec_result.len(),
            duration_construct_search_vec,
            duration_search,
            search_bbox_result.len(),
            duration_construct_search_bbox,
            duration_search_inverse
        );

        return (
            search_vec_result.into_iter().map(|x| x.vec).collect(),
            search_bbox_result.into_iter().map(|x| x.bbox).collect(),
        );
    }

    let max_cardinality = *CARDINALITIES.iter().max().unwrap();
    let mut rng = rand::thread_rng();
    let vecs10 = make_n_k_dimensional_vecs_i16_with_labels::<10>(max_cardinality, &mut rng);
    let bboxes10 = make_n_k_dimensional_bboxes_i16_with_labels::<10>(max_cardinality, &mut rng);
    let vecs30 = make_n_k_dimensional_vecs_i16_with_labels::<30>(max_cardinality, &mut rng);
    let bboxes30 = make_n_k_dimensional_bboxes_i16_with_labels::<30>(max_cardinality, &mut rng);
    let vecs100 = make_n_k_dimensional_vecs_i16_with_labels::<100>(max_cardinality, &mut rng);
    let bboxes100 = make_n_k_dimensional_bboxes_i16_with_labels::<100>(max_cardinality, &mut rng);
    for n in &CARDINALITIES {
        let vecs10_this_cardinality = vecs10.iter().take(*n).cloned().collect();
        let bboxes10_this_cardinality = bboxes10.iter().take(*n).cloned().collect();
        let vecs30_this_cardinality = vecs30.iter().take(*n).cloned().collect();
        let bboxes30_this_cardinality = bboxes30.iter().take(*n).cloned().collect();
        let vecs100_this_cardinality = vecs100.iter().take(*n).cloned().collect();
        let bboxes100_this_cardinality = bboxes100.iter().take(*n).cloned().collect();
        let (_, _) = run_search_tests::<10, LinearSearch<10>>(
            &vecs10_this_cardinality,
            &bboxes10_this_cardinality,
            "Linear",
        );
        let (_, _) = run_search_tests::<30, LinearSearch<30>>(
            &vecs30_this_cardinality,
            &bboxes30_this_cardinality,
            "Linear",
        );
        let (_, _) = run_search_tests::<100, LinearSearch<100>>(
            &vecs100_this_cardinality,
            &bboxes100_this_cardinality,
            "Linear",
        );
    }
}
