use crate::{
    db::DB,
    models::internal_models::{internal_access_code::InternalAccessCode, shared::Save},
};

pub fn to_i16(n: f64, min: f64, max: f64) -> i16 {
    //get percent from min to max
    let percent = (n - min) / (max - min);
    //get value from -32768 to 32767
    let value = (percent * 65535.0) - 32768.0;
    value as i16
}

pub fn to_f64(n: i16, min: f64, max: f64) -> f64 {
    //get percent from -32768 to 32767
    let percent = (n as f64 + 32768.0) / 65535.0;
    //get value from min to max
    let value = percent * (max - min) + min;
    value
}

pub fn generate_access_codes(n: usize, db: &DB) -> Result<Vec<String>, Box<dyn std::error::Error>> {
    let mut access_codes = Vec::with_capacity(n);
    for _ in 0..n {
        let access_code = InternalAccessCode::gen(&true);
        let code = access_code.code.clone();
        access_code.save(db).unwrap();
        access_codes.push(code);
    }
    Ok(access_codes)
}
