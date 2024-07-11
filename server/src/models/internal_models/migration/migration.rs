//allow unreachable code for this file
#![allow(unreachable_code)]

use rkyv::{
    ser::serializers::{
        AlignedSerializer, AllocScratch, CompositeSerializer, FallbackScratch, HeapScratch,
        SharedSerializeMap,
    },
    AlignedVec, Serialize,
};

use crate::{
    db::{DB, SCRATCH_SPACE_SIZE},
    models::{
        api_models::{api_image::ApiImageWritable, api_user::ApiUserWritable},
        internal_models::{
            internal_access_code::InternalAccessCode,
            internal_chat::InternalChat,
            internal_image::{Access, InternalImage},
            internal_message::InternalMessage,
            internal_user::InternalUser,
            migration::internal_user::internal_user_v0::InternalUserV0,
            shared::{Insertable, InternalUuid, Save},
        },
    },
};

pub trait Migratable: Sized {
    type NextVersion: Serialize<
            CompositeSerializer<
                AlignedSerializer<AlignedVec>,
                FallbackScratch<HeapScratch<SCRATCH_SPACE_SIZE>, AllocScratch>,
                SharedSerializeMap,
            >,
        > + Insertable;
    type ExtraData;
    fn migrate(
        &self,
        db: &DB,
        extra_data: Self::ExtraData,
    ) -> Result<InternalUuid<Self::NextVersion>, Box<dyn std::error::Error>>;
    fn migration_message() -> &'static str;
}

// DB implementation
impl DB {
    pub fn migrate_model<T: Migratable + Insertable>(
        &self,
        model: T,
        extra_data: T::ExtraData,
    ) -> Result<InternalUuid<T::NextVersion>, Box<dyn std::error::Error>> {
        let uuid = model.migrate(self, extra_data)?;
        Ok(uuid)
    }

    pub fn migrate_all(&self) -> Result<(), Box<dyn std::error::Error>> {
        let db_version_user = self.get_version::<InternalUser>()?;
        let current_version_user = InternalUser::version();
        let db_version_chat = self.get_version::<InternalChat>()?;
        let current_version_chat = InternalChat::version();
        let db_version_image = self.get_version::<InternalImage>()?;
        let current_version_image = InternalImage::version();
        let db_version_message = self.get_version::<InternalMessage>()?;
        let current_version_message = InternalMessage::version();
        let db_version_access_code = self.get_version::<InternalAccessCode>()?;
        let current_version_access_code = InternalAccessCode::version();
        if db_version_user < current_version_user {
            log::info!(
                "Migrating InternalUser from version {} to {}",
                db_version_user,
                current_version_user
            );

            match db_version_user {
                0 => {
                    log::info!("{}", InternalUserV0::migration_message());
                    log::info!("Db upgraded from version 0 to 1 for InternalUser");
                    self.set_version::<InternalUser>(1)?;
                    let admin_user = make_admin_user(self);
                    admin_user.save(self)?;
                    let users = self.iter_obj::<InternalUserV0>()?;
                    for user in users {
                        self.migrate_model(user?, ())?;
                    }
                    log::info!("Migrated InternalUser from version 0 to 1 successfully!");
                }
                _ => {
                    return Err(format!(
                        "Unknown version {} for InternalUser",
                        db_version_user
                    ))?;
                }
            }
        }

        if db_version_chat < current_version_chat {
            log::info!(
                "Migrating InternalChat from version {} to {}",
                db_version_chat,
                current_version_chat
            );
            match db_version_chat {
                _ => {
                    return Err(format!(
                        "Unknown version {} for InternalChat",
                        db_version_chat
                    ))?;
                }
            }
        }

        if db_version_image < current_version_image {
            log::info!(
                "Migrating InternalImage from version {} to {}",
                db_version_image,
                current_version_image
            );
            match db_version_image {
                _ => {
                    return Err(format!(
                        "Unknown version {} for InternalImage",
                        db_version_image
                    ))?;
                }
            }
        }

        if db_version_message < current_version_message {
            log::info!(
                "Migrating InternalMessage from version {} to {}",
                db_version_message,
                current_version_message
            );
            match db_version_message {
                _ => {
                    return Err(format!(
                        "Unknown version {} for InternalMessage",
                        db_version_message
                    ))?;
                }
            }
        }

        if db_version_access_code < current_version_access_code {
            log::info!(
                "Migrating InternalAccessCode from version {} to {}",
                db_version_access_code,
                current_version_access_code
            );
            match db_version_access_code {
                _ => {
                    return Err(format!(
                        "Unknown version {} for InternalAccessCode",
                        db_version_access_code
                    ))?;
                }
            }
        }

        return Ok(());
    }
}
const ADMIN_UUID: &str = "00000000-0000-0000-0000-000000000000";
pub fn get_admin_uuid() -> InternalUuid<InternalUser> {
    InternalUuid::from_str(ADMIN_UUID)
}

pub fn make_admin_user(db: &DB) -> InternalUser {
    let admin_password = std::env::var("ADMIN_PASSWORD")
        .map_err(|_| "ADMIN_PASSWORD not set")
        .unwrap();

    let admin_image = ApiImageWritable::new_admin();
    let internal_admin_image = admin_image.to_internal(Access::Everyone).unwrap();
    let admin_image_uuid = internal_admin_image.save(db).unwrap();

    let admin = ApiUserWritable {
        uuid: get_admin_uuid().into(),
        images: vec![admin_image_uuid.clone().into()],
        username: "admin".to_string(),
        display_name: "The Friendly Admin".to_string(),
        description: "The friendly admin, they're here to answer any of your questions".to_string(),
        prefs: vec![],
        props: vec![],
        birthdate: 0,
        preview_image: Some(admin_image_uuid.into()),
        password: Some(admin_password),
        is_bot: false,
    };
    let mut internal_admin = admin.to_internal(db, true).unwrap();
    internal_admin.uuid = InternalUuid::from_str(ADMIN_UUID);

    return internal_admin;
}
