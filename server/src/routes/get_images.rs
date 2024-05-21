use actix_web::Error;

use paperclip::actix::{
    api_v2_operation, post,
    web::{self, Json},
    Apiv2Schema,
};
use serde::{Deserialize, Serialize};

use crate::{
    db::DB,
    models::{
        api_models::{api_image::ApiImage, shared::ApiUuid},
        internal_models::{internal_image::InternalImage, shared::InternalUuid},
    },
    routes::shared::route_body_mut_db,
};

#[derive(Debug, Clone, Serialize, Deserialize, Apiv2Schema)]
struct GetImagesInput {
    image_uuid: ApiUuid<InternalImage>,
    images: Vec<ApiUuid<InternalImage>>,
}

#[api_v2_operation]
#[post("/get_images")]
pub fn get_images(
    db: web::Data<DB>,
    req: web::HttpRequest,
    body: Json<GetImagesInput>,
) -> Result<Json<Vec<ApiImage>>, Error> {
    route_body_mut_db(db, req, body, |db, user, body| {
        //is this user in this image?

        let images = body
            .images
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
