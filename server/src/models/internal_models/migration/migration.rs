use crate::{db::DB, models::internal_models::shared::Bucket};

pub trait Migratable: Sized {
    type NextVersion: Sized;
    fn migrate(&self, db: &DB) -> Result<Self::NextVersion, Box<dyn std::error::Error>>;
}

// DB implementation
impl DB {
    pub fn migrate_model<T: Migratable + Bucket>(
        &self,
        model: T,
    ) -> Result<T::NextVersion, Box<dyn std::error::Error>> {
        model.migrate(self)
    }
}
