use actix_web::{Error, HttpRequest};

use paperclip::actix::{
    api_v2_operation, post,
    web::{self, Json},
    Apiv2Schema,
};
use serde::Deserialize;

use crate::{
    db::DB,
    models::{
        api_models::{api_image::ApiImageWritable, shared::ApiUuid},
        internal_models::{
            internal_image::{Access, InternalImage},
            internal_user::InternalUser,
        },
    },
    routes::shared::route_body_mut_db,
};

use crate::models::internal_models::shared::Save;

#[derive(Debug, Deserialize, Apiv2Schema)]
struct PutImageInput {
    content: String,
    access: Option<Vec<ApiUuid<InternalUser>>>,
}

#[api_v2_operation]
#[post("/put_image")]
fn put_image(
    db: web::Data<DB>,
    req: HttpRequest,
    body: Json<PutImageInput>,
) -> Result<Json<ApiUuid<InternalImage>>, Error> {
    route_body_mut_db(db, req, body, |db, mut user, img_content| {
        #[allow(deprecated)]
        let img_content_bytes = base64::decode(img_content.content).map_err(|e| {
            log::error!("Failed to decode image {:?}", e);
            actix_web::error::ErrorBadRequest("Failed to decode image")
        })?;
        let new_image = ApiImageWritable::new(img_content_bytes);

        let access = match img_content.access {
            Some(access) => {
                if access.is_empty() {
                    Access::Everyone
                } else {
                    Access::UserList(access.into_iter().map(|u| u.into()).collect::<Vec<_>>())
                }
            }
            None => Access::Everyone,
        };

        let new_image_internal = new_image.to_internal(access).map_err(|e| {
            log::error!("Failed to convert image {:?}", e);
            actix_web::error::ErrorInternalServerError("Failed to convert image")
        })?;

        let uuid = new_image_internal.save(db).map_err(|e| {
            log::error!("Failed to save user {:?}", e);
            actix_web::error::ErrorInternalServerError("Failed to save user")
        })?;

        user.owned_images.push(uuid.clone());

        user.save(db).map_err(|e| {
            log::error!("Failed to save user {:?}", e);
            actix_web::error::ErrorInternalServerError("Failed to save user")
        })?;

        Ok(uuid.into())
    })
}
