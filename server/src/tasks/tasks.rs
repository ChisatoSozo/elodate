use crate::{
    db::DB,
    models::internal_models::{internal_user::InternalUser, shared::Save},
    tasks::{update_age::update_age, update_elo::update_elo},
};

pub fn run_all_tasks(db: &DB) -> Result<(), Box<dyn std::error::Error>> {
    println!("Running all tasks");
    for user in db.iter_obj::<InternalUser>("users")? {
        let mut user = user?;
        println!("Running tasks for user: {}", user.username);
        update_age(&mut user);
        update_elo(&mut user);
        user.save(db)?;
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::db::DB;

    #[test]
    fn test_run_all_tasks() {
        let db = DB::new("dummy").unwrap();
        let start_time = std::time::Instant::now();
        for _ in 0..100 {
            assert!(run_all_tasks(&db).is_ok());
        }

        let end_time = start_time.elapsed();
        println!("Ran all tasks in {:?}", end_time);
    }
}
