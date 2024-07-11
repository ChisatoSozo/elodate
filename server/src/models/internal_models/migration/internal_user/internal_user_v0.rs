use crate::{
    db::DB,
    models::internal_models::{
        internal_chat::InternalChat,
        internal_image::InternalImage,
        internal_prefs::{LabeledPreferenceRange, LabeledProperty},
        internal_user::{BotProps, InternalRating, InternalUser, Notification, TimestampedAction},
        migration::migration::{get_admin_uuid, Migratable},
        shared::{Insertable, InternalUuid, Save},
    },
};

#[derive(Debug, rkyv::Serialize, rkyv::Deserialize, rkyv::Archive, serde::Serialize, paperclip::actix::Apiv2Schema)]
#[archive(compare(PartialEq), check_bytes)]
pub struct InternalUserV0 {
    pub uuid: InternalUuid<InternalUser>,
    pub hashed_password: String,
    pub elo: f32,
    pub ratings: Vec<InternalRating>,
    pub seen: Vec<InternalUuid<InternalUser>>,
    pub chats: Vec<InternalUuid<InternalChat>>,
    pub images: Vec<InternalUuid<InternalImage>>,
    pub preview_image: Option<InternalUuid<InternalImage>>,
    pub username: String,
    pub display_name: String,
    pub description: String,
    pub birthdate: i64,
    pub prefs: Vec<LabeledPreferenceRange>,
    pub props: Vec<LabeledProperty>,
    pub owned_images: Vec<InternalUuid<InternalImage>>,
    pub actions: Vec<TimestampedAction>,
    pub notifications: Vec<Notification>,
    pub published: bool,
    pub bot_props: Option<BotProps>,
    pub is_admin: bool,
}

impl Migratable for InternalUserV0 {
    type NextVersion = InternalUser;
    type ExtraData = ();
    fn migrate(
        &self,
        db: &DB,
        _: (),
    ) -> Result<InternalUuid<Self::NextVersion>, Box<dyn std::error::Error>> {
        if self.uuid == get_admin_uuid() {
            log::info!("User is already admin, skipping migration");
            let user = InternalUser {
                uuid: self.uuid.clone(),
                hashed_password: self.hashed_password.clone(),
                elo: self.elo,
                ratings: self.ratings.clone(),
                seen: self.seen.clone(),
                chats: self.chats.clone(),
                images: self.images.clone(),
                preview_image: self.preview_image.clone(),
                username: self.username.clone(),
                display_name: self.display_name.clone(),
                description: self.description.clone(),
                birthdate: self.birthdate,
                prefs: self.prefs.clone(),
                props: self.props.clone(),
                owned_images: self.owned_images.clone(),
                actions: self.actions.clone(),
                notifications: self.notifications.clone(),
                published: self.published,
                bot_props: self.bot_props.clone(),
            };
            return user.save(db);
        }
        let (chat, message) = InternalChat::new_admin_chat(&self.uuid);
        let chat_uuid = chat.save(db)?;
        let chat = chat_uuid.load(db)?;
        let mut chat = match chat {
            Some(chat) => chat,
            None => {
                return Err("Failed to load chat".into());
            }
        };

        let user = InternalUser {
            uuid: self.uuid.clone(),
            hashed_password: self.hashed_password.clone(),
            elo: self.elo,
            ratings: self.ratings.clone(),
            seen: self.seen.clone(),
            chats: self
                .chats
                .clone()
                .into_iter()
                .chain(std::iter::once(chat_uuid.clone()))
                .collect(),
            images: self.images.clone(),
            preview_image: self.preview_image.clone(),
            username: self.username.clone(),
            display_name: self.display_name.clone(),
            description: self.description.clone(),
            birthdate: self.birthdate,
            prefs: self.prefs.clone(),
            props: self.props.clone(),
            owned_images: self.owned_images.clone(),
            actions: self.actions.clone(),
            notifications: self.notifications.clone(),
            published: self.published,
            bot_props: self.bot_props.clone(),
        };

        let user_uuid = user.save(db)?;

        message
            .into_internal(&get_admin_uuid(), &chat, db)?
            .save(&mut chat, db)?;

        let mut admin = db.get_admin()?;
        let mut admin_chats = admin.chats;
        admin_chats.push(chat_uuid);
        admin.chats = admin_chats;
        println!(
            "adding chat to admin, admin now has {} chats",
            admin.chats.len()
        );
        admin.save(db)?;

        Ok(user_uuid)
    }

    fn migration_message() -> &'static str {
        "Adding admin chat to each user and creating the admin user"
    }
}

impl Insertable for InternalUserV0 {
    fn version() -> u64 {
        0
    }
}
