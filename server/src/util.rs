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
pub async fn save_as_webp(
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
