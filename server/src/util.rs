// Module to convert images to webp

use image::io::Reader as ImageReader;
use image::{DynamicImage, EncodableLayout}; // Using image crate: https://github.com/image-rs/image
use webp::{Encoder, WebPMemory}; // Using webp crate: https://github.com/jaredforth/webp

use std::error::Error;
use std::fs::File;
use std::io::Write;
use std::path::Path;

use crate::models::image::ElodateImageFormat;

/*
    Function which converts an image in PNG or JPEG format to WEBP.
    :param file_path: &String with the path to the image to convert.
    :return Option<String>: Return the path of the WEBP-image as String when succesfull, returns None if function fails.
*/
pub fn save_as_webp(
    b64_content: &String,
    format: &ElodateImageFormat,
    file_path: &Path,
) -> Result<(), Box<dyn Error>> {
    // Decode base64 content
    #[allow(deprecated)]
    let decoded = base64::decode(b64_content)?;

    let format = match format {
        ElodateImageFormat::PNG => image::ImageFormat::Png,
        ElodateImageFormat::JPEG => image::ImageFormat::Jpeg,
        ElodateImageFormat::WEBP => image::ImageFormat::WebP,
    };
    // Open path as DynamicImage
    let image: DynamicImage =
        ImageReader::with_format(std::io::Cursor::new(decoded), format).decode()?;
    // Make webp::Encoder from DynamicImage
    let encoder: Encoder = Encoder::from_image(&image)?;

    // Encode image into WebPMemory
    let encoded_webp: WebPMemory = encoder.encode(65f32);

    // Write WebPMemory to file
    let mut file = File::create(file_path)?;
    file.write_all(encoded_webp.as_bytes())?;
    Ok(())
}

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
