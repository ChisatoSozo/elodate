use std::error::Error;

use crate::models::internal_models::shared::Save;
use crate::{db::DB, models::internal_models::internal_user::InternalUser};

pub fn upsert_user(user: InternalUser, db: &mut DB) -> Result<(), Box<dyn Error>> {
    user.save(db).map_err(|e| {
        println!("Failed to insert user into database {:?}", e);
        actix_web::error::ErrorInternalServerError("Failed to insert user into database")
    })?;

    Ok(())
}
