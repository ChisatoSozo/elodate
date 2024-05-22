use actix_web::Error;

use paperclip::actix::{
    api_v2_operation, post,
    web::{self, Json},
};

use crate::{
    db::DB,
    models::{
        api_models::{api_image::ApiImage, shared::ApiUuid},
        internal_models::{internal_image::InternalImage, shared::InternalUuid},
    },
    routes::shared::route_body_mut_db,
};

#[api_v2_operation]
#[post("/get_images")]
pub fn get_images(
    db: web::Data<DB>,
    req: web::HttpRequest,
    body: Json<Vec<ApiUuid<InternalImage>>>,
) -> Result<Json<Vec<ApiImage>>, Error> {
    route_body_mut_db(db, req, body, |db, user, body| {
        let images = body
            .into_iter()
            .map(|image_uuid| {
                let internal_image_uuid: InternalUuid<InternalImage> = image_uuid.into();
                let image = internal_image_uuid.load(db).map_err(|e| {
                    println!("Failed to get image {:?}", e);
                    actix_web::error::ErrorInternalServerError("Failed to get image")
                })?;

                let image = match image {
                    Some(image) => image,
                    None => return Err(actix_web::error::ErrorNotFound("Image not found")),
                };

                Ok(image)
            })
            .collect::<Result<Vec<_>, _>>()?;

        let api_images: Vec<ApiImage> = images
            .into_iter()
            .map(|image| ApiImage::from_internal(image, &user))
            .collect::<Result<Vec<_>, _>>()?;
        Ok(api_images)
    })
}
