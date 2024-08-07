#[test]
fn insert_dummy_data() -> Result<(), Box<dyn std::error::Error>> {
    use crate::{
        models::{api_models::api_user::ApiUserWritable, internal_models::shared::Save},
        test::fake::Gen,
    };

    use crate::{
        db::DB,
        models::internal_models::{
            internal_chat::InternalChat, internal_message::InternalMessage,
            internal_user::InternalUser, shared::InternalUuid,
        },
    };
    use fake::Fake;

    use bcrypt::hash;

    log::info!("Destroying db");
    DB::destroy_database_for_real_dangerous("dummy");
    log::info!("Creating db");
    let db = DB::new("dummy").unwrap();
    db.migrate_all().unwrap();
    log::info!("inserting dummy data");

    let mut uuids = vec![];

    let start_time = std::time::Instant::now();
    let count = 10000;
    for i in 0..count {
        if i % 10 == 0 {
            log::info!("Inserted {} users", i);
        }
        let user: ApiUserWritable = ApiUserWritable::gen(&db);
        let user: InternalUser = user.to_internal(&db, true)?;
        uuids.push(user.uuid.clone());
        user.save(&db)?;
    }
    let end_time = start_time.elapsed();
    log::info!("Inserted {} users in {:?}", count, end_time);
    log::info!("That's a user every {:?}", end_time / count as u32);
    log::info!(
        "Or, {} users per second",
        count as f64 / end_time.as_secs_f64()
    );

    let size_on_disk = db.store.size_on_disk().unwrap();
    //format as kb/mb/gb
    let size_on_disk = if size_on_disk < 1024 {
        format!("{} bytes", size_on_disk)
    } else if size_on_disk < 1024 * 1024 {
        format!("{:.2} kb", size_on_disk as f64 / 1024.0)
    } else if size_on_disk < 1024 * 1024 * 1024 {
        format!("{:.2} mb", size_on_disk as f64 / 1024.0 / 1024.0)
    } else {
        format!("{:.2} gb", size_on_disk as f64 / 1024.0 / 1024.0 / 1024.0)
    };

    log::info!("Database size on disk: {}", size_on_disk);

    //upsert main user
    let mut user: ApiUserWritable = ApiUserWritable::gen(&db);
    user.is_bot = false;
    let mut user: InternalUser = user.to_internal(&db, true).unwrap();
    user.published = true;
    user.username = "asdf".to_string();
    user.hashed_password = hash("asdfasdf", 4)?;

    let uuid = user.save(&db).unwrap();
    let mut user = uuid.load(&db).unwrap().unwrap();

    //upsert chats
    for n in 0..5 {
        let chat_uuid = InternalUuid::new();
        let messages: Vec<InternalMessage> = (0..4)
            .map(|n| InternalMessage {
                uuid: InternalUuid::new(),
                sent_at: chrono::Utc::now().timestamp_millis() / 1000,
                author: if n % 2 == 0 {
                    (&user).uuid.clone()
                } else {
                    uuids[n].clone()
                },
                content: fake::faker::lorem::en::Sentence(1..2).fake(),
                image: None,
                read_by: vec![],
                edited: false,
                chat: chat_uuid.clone(),
            })
            .collect();

        let mut chat = InternalChat {
            uuid: chat_uuid,
            users: vec![user.uuid.clone(), uuids[n].clone()],
            messages: messages.iter().map(|m| m.uuid.clone()).collect(),
            most_recent_message: messages.last().unwrap().content.clone(),
            unread: vec![0, 0],
            most_recent_sender: Some(uuids[n].clone()),
            most_recent_message_sent_at: messages.last().unwrap().sent_at,
        };

        for message in messages {
            message.save(&mut chat, &db).unwrap();
        }
        user.chats.push(chat.uuid.clone());
        chat.save(&db)?;
    }
    user.published = true;

    user.save(&db).unwrap();

    return Ok(());
}
