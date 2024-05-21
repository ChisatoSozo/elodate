use super::{api_image::ApiImage, shared::ApiUuid};
use crate::{
    db::DB,
    elo::elo_min,
    models::internal_models::{
        internal_chat::InternalChat,
        internal_image::{Access, InternalImage},
        internal_preferences::{Preferences, Properties},
        internal_user::InternalUser,
        shared::{InternalUuid, Save},
    },
};
use bcrypt::hash;
use paperclip::actix::Apiv2Schema;
use serde::{Deserialize, Serialize};
use std::error::Error;

#[derive(Debug, Clone, Serialize, Deserialize, Apiv2Schema)]
pub struct ApiUser {
    pub uuid: ApiUuid<InternalUser>,
    pub images: Vec<ApiUuid<InternalImage>>,
    pub elo: u32,
    pub username: String,
    pub display_name: String,
    pub description: String,
    pub preferences: Preferences,
    pub properties: Properties,
    pub birthdate: i64,
    pub published: bool,
    pub chats: Option<Vec<ApiUuid<InternalChat>>>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Apiv2Schema)]
pub struct ApiUserWritable {
    pub uuid: ApiUuid<InternalUser>,
    pub images: Vec<ApiImage>,
    pub username: String,
    pub password: Option<String>,
    pub display_name: String,
    pub description: String,
    pub preferences: Preferences,
    pub properties: Properties,
    pub birthdate: i64,
    pub published: bool,
}

impl ApiUser {
    pub fn from_internal(
        user: InternalUser,
        requester: &InternalUser,
    ) -> Result<Self, Box<dyn Error>> {
        Ok(ApiUser {
            uuid: user.uuid.clone().into(),
            images: user.images.into_iter().map(|i| i.into()).collect(),
            elo: user.elo,
            username: user.username,
            display_name: user.display_name,
            description: user.description,
            preferences: user.preferences,
            properties: user.properties,
            birthdate: user.birthdate,
            published: user.published,
            chats: if requester.uuid == user.uuid {
                Some(user.chats.into_iter().map(|c| c.into()).collect())
            } else {
                None
            },
        })
    }
}

impl ApiUserWritable {
    pub fn to_internal(self, db: &DB) -> Result<InternalUser, Box<dyn Error>> {
        let internal_uuid: InternalUuid<InternalUser> = self.uuid.into();
        let internal_user = internal_uuid.load(db)?;

        let hashed_password = if let Some(internal_user) = &internal_user {
            internal_user.hashed_password.clone()
        } else if let Some(password) = self.password {
            hash(password, 4)?
        } else {
            return Err("No password for no internal user".into());
        };

        if let Some(internal_user) = &internal_user {
            for image in &internal_user.images {
                image.clone().delete(db)?;
            }
        }

        let mut internal_images = Vec::new();
        for image in self.images {
            let internal_image: InternalImage = image.to_internal(Access::Everyone);
            internal_images.push(internal_image.save(db)?);
        }

        Ok(InternalUser {
            uuid: internal_uuid,
            hashed_password,
            elo: internal_user.as_ref().map_or(elo_min(), |u| u.elo.clone()),
            ratings: internal_user.as_ref().map_or(vec![], |u| u.ratings.clone()),
            seen: internal_user.as_ref().map_or(vec![], |u| u.seen.clone()),
            chats: internal_user.as_ref().map_or(vec![], |u| u.chats.clone()),
            images: internal_images,
            username: self.username,
            display_name: self.display_name,
            description: self.description,
            birthdate: self.birthdate,
            preferences: self.preferences,
            properties: self.properties,
            published: self.published,
        })
    }
}
