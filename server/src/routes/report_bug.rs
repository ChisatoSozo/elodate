use std::fs;

use actix_web::Error;

use paperclip::actix::{api_v2_operation, post, web::Json, Apiv2Schema};
use serde::Deserialize;
use uuid::Uuid;

#[derive(Debug, Clone, Deserialize, Apiv2Schema)]
struct ReportBugInput {
    content: String,
    imageb64: String,
}

#[api_v2_operation]
#[post("/report_bug")]
fn report_bug(body: Json<ReportBugInput>) -> Result<Json<bool>, Error> {
    //decode image64
    #[allow(deprecated)]
    let bytes = base64::decode(&body.imageb64).map_err(|e| {
        println!("Failed to decode image {:?}", e);
        std::io::Error::new(std::io::ErrorKind::Other, "Failed to decode image")
    })?;
    //autodetect format and convert to jpg
    let img = image::load_from_memory(&bytes)
        .map_err(|e| {
            println!("Failed to load image {:?}", e);
            std::io::Error::new(std::io::ErrorKind::Other, "Failed to load image")
        })?
        .to_rgb8();
    let mut buf = Vec::new();
    image::codecs::jpeg::JpegEncoder::new(&mut buf)
        .encode(
            &img,
            img.width(),
            img.height(),
            image::ExtendedColorType::Rgb8,
        )
        .map_err(|e| {
            println!("Failed to encode image {:?}", e);
            std::io::Error::new(std::io::ErrorKind::Other, "Failed to encode image")
        })?;
    //save image
    let report_uuid = Uuid::new_v4();
    //save image and text content to folder report/report_uuid/*

    //if folder does not exist, create it
    fs::create_dir_all(format!("report/{}", report_uuid))?; //create folder
    fs::write(
        format!("report/{}/report.txt", report_uuid),
        body.content.clone(),
    )?; //write text content
    fs::write(format!("report/{}/report.jpg", report_uuid), buf)?; //write image content
    return Ok(Json(true));
}
