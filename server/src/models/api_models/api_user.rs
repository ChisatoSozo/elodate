use super::{api_image::ApiImage, shared::ApiUuid};
use crate::{
    db::DB,
    models::internal_models::{
        internal_preferences::{Preferences, Properties},
        internal_user::InternalUser,
    },
};
use std::error::Error;

use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ApiUser {
    pub uuid: ApiUuid<ApiUser, InternalUser>,
    pub images: Vec<ApiImage>,
    pub elo: u32,
    pub username: String,
    pub display_name: String,
    pub description: String,
    pub preferences: Preferences,
    pub properties: Properties,
    pub published: bool,
}

impl ApiUser {
    fn from_internal(user: InternalUser, db: &mut DB) -> Result<Self, Box<dyn Error>> {
        let images = user
            .images
            .iter()
            .map(|uuid| {
                let image = uuid.load(db);
                let image = match image {
                    Ok(Some(image)) => image,
                    Ok(None) => return Err("Image not found".into()),
                    Err(e) => return Err(e),
                };
                Ok(image.into())
            })
            .collect::<Result<Vec<ApiImage>, Box<dyn Error>>>()?;

        Ok(ApiUser {
            uuid: user.uuid.id.into(),
            images,
            elo: user.elo,
            username: user.username,
            display_name: user.display_name,
            description: user.description,
            preferences: user.preferences,
            properties: user.properties,
            published: user.published,
        })
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ApiUserWritable {
    pub uuid: ApiUuid<ApiUser, InternalUser>,
    pub images: Vec<ApiImage>,
    pub username: String,
    pub display_name: String,
    pub description: String,
    pub preferences: Preferences,
    pub properties: Properties,
    pub published: bool,
}

impl ApiUserWritable {
    fn from_internal(user: InternalUser, db: &mut DB) -> Result<Self, Box<dyn Error>> {
        let images = user
            .images
            .iter()
            .map(|uuid| {
                let image = uuid.load(db);
                let image = match image {
                    Ok(Some(image)) => image,
                    Ok(None) => return Err("Image not found".into()),
                    Err(e) => return Err(e),
                };
                Ok(image.into())
            })
            .collect::<Result<Vec<ApiImage>, Box<dyn Error>>>()?;

        Ok(ApiUserWritable {
            uuid: user.uuid.id.into(),
            images,
            username: user.username,
            display_name: user.display_name,
            description: user.description,
            preferences: user.preferences,
            properties: user.properties,
            published: user.published,
        })
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ApiUserPreview {
    pub uuid: ApiUuid<ApiUser, InternalUser>,
    pub preview_image: ApiImage,
    pub username: String,
    pub display_name: String,
}

impl ApiUserPreview {
    fn from_internal(user: InternalUser, db: &mut DB) -> Result<Self, Box<dyn Error>> {
        let preview_image = user
            .images
            .iter()
            .map(|uuid| {
                let image = uuid.load(db);
                let image = match image {
                    Ok(Some(image)) => image,
                    Ok(None) => return Err("Image not found".into()),
                    Err(e) => return Err(e),
                };
                Ok(image.into())
            })
            .next()
            .ok_or("No images found")??;

        Ok(ApiUserPreview {
            uuid: user.uuid.id.into(),
            preview_image,
            username: user.username,
            display_name: user.display_name,
        })
    }
}
