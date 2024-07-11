use actix_web::{Error, HttpRequest};

use paperclip::actix::{
    api_v2_operation, post,
    web::{self, Json},
};

use crate::{
    db::DB,
    models::{
        api_models::shared::ApiUuid,
        internal_models::{internal_image::InternalImage, shared::InternalUuid},
    },
    routes::shared::route_body_mut_db,
};

use crate::models::internal_models::shared::Save;

#[api_v2_operation]
#[post("/delete_image")]
fn delete_image(
    db: web::Data<DB>,
    req: HttpRequest,
    body: Json<ApiUuid<InternalImage>>,
) -> Result<Json<bool>, Error> {
    route_body_mut_db(db, req, body, |db, mut user, img_uuid| {
        let img_uuid_internal: InternalUuid<InternalImage> = img_uuid.into();
        //is this image mine?
        if user
            .owned_images
            .iter()
            .find(|i| i == &&img_uuid_internal)
            .is_none()
        {
            return Err(actix_web::error::ErrorBadRequest("Image not found"));
        }

        //remove from owned images
        user.owned_images.retain(|i| i != &img_uuid_internal);

        //remove if it's the preview image
        if user.preview_image.as_ref() == Some(&img_uuid_internal) {
            user.preview_image = None
        }

        //remove from pfp
        user.images.retain(|i| i != &img_uuid_internal);

        img_uuid_internal.delete(db)?;

        //update user
        user.save(db)?;

        Ok(true)
    })
}
