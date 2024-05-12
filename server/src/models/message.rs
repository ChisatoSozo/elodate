use paperclip::actix::Apiv2Schema;
use serde::{Deserialize, Serialize};

// A trait that the Validate derive will impl
use validator::Validate;

use crate::db::DB;

use super::{
    chat::Chat,
    image::{ElodateImageFormat, Image},
    shared::UuidModel,
    user::User,
};

#[derive(Debug, Validate, Serialize, Deserialize, Apiv2Schema, Clone)]
pub struct Message {
    pub uuid: UuidModel,
    pub sent_at: i64,
    pub author: UuidModel,
    #[validate(length(min = 1, message = "Message content must not be empty"))]
    pub content: String,
    pub image: Option<Image>,
    pub image_type: Option<ElodateImageFormat>,
}

impl Message {
    pub fn get_path_for_image(
        &self,
        chat: &Chat,
        sender: &User,
        image_type: &ElodateImageFormat,
        db: &DB,
    ) -> String {
        let user_image_path = db.path.clone() + "/images/" + &sender.uuid.0;
        let chat_id = chat.uuid.0.clone();
        let message_id = self.uuid.0.clone();
        let image_path = user_image_path.clone()
            + "/"
            + &chat_id
            + "/"
            + &message_id
            + "."
            + image_type.to_ext();

        image_path
    }

    pub fn fill_image(
        &mut self,
        chat: &Chat,
        user: &User,
        db: &DB,
    ) -> Result<(), Box<dyn std::error::Error>> {
        let image_type = match &self.image_type {
            Some(image_type) => image_type,
            None => return Ok(()),
        };
        let path = self.get_path_for_image(chat, user, image_type, db);

        let exists = std::path::Path::new(&path).exists();
        if !exists {
            self.image = None;
            self.image_type = None;
            return Ok(());
        }

        let image = Image::load(&path)?;

        self.image = Some(image);
        Ok(())
    }
}
