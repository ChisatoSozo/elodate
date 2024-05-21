use std::error::Error;
//TODO: encryption at rest

use crate::db::DB;

use super::{
    internal_image::InternalImage,
    internal_user::InternalUser,
    shared::{InternalUuid, Save},
};

#[derive(Debug, Clone, rkyv::Archive, rkyv::Serialize, rkyv::Deserialize)]
#[archive(compare(PartialEq), check_bytes)]
pub struct InternalMessage {
    pub uuid: InternalUuid<InternalMessage>,
    pub sent_at: i64,
    pub author: InternalUuid<InternalUser>,
    pub content: String,
    pub image: Option<InternalUuid<InternalImage>>,
    pub read_by: Vec<InternalUuid<InternalUser>>,
}

impl Save for InternalMessage {
    fn save(self, db: &mut DB) -> Result<(), Box<dyn Error>> {
        db.write_object(&self.uuid, &self)?;
        Ok(())
    }
}

//TODO: probably bad logic here
impl InternalMessage {
    pub fn save_ref_do_not_use_unless_its_that_one_weird_message_place(
        &self,
        db: &mut DB,
    ) -> Result<(), Box<dyn Error>> {
        db.write_object(&self.uuid, &self)?;
        Ok(())
    }
}
