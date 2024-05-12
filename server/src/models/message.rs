use paperclip::actix::Apiv2Schema;
use serde::{Deserialize, Serialize};

// A trait that the Validate derive will impl
use validator::Validate;

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
    pub fn get_path_for_image(&self, chat: &Chat, sender: &User) -> Option<String> {
        let user_image_path = "images/".to_owned() + &sender.uuid.0;
        let chat_id = chat.uuid.0.clone();
        let message_id = self.uuid.0.clone();
        let image_type = self.image_type.clone()?;
        let image_path = user_image_path.clone()
            + "/"
            + &chat_id
            + "/"
            + &message_id
            + "."
            + image_type.to_ext();

        Some(image_path)
    }

    pub fn fill_image(
        &mut self,
        chat: &Chat,
        user: &User,
    ) -> Result<(), Box<dyn std::error::Error>> {
        let path = self.get_path_for_image(chat, user);

        let path = match path {
            Some(path) => path,
            None => return Ok(()),
        };
        //path exists

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
