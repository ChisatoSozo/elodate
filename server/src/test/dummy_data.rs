#[test]
fn insert_dummy_data() -> Result<(), Box<dyn std::error::Error>> {
    use crate::{
        db::DB,
        models::internal_models::{
            internal_chat::InternalChat,
            internal_message::InternalMessage,
            internal_user::{InternalRating, InternalUser},
            shared::{Gen, InternalUuid, Save},
        },
    };
    use fake::Fake;

    use bcrypt::hash;

    println!("Destroying db");
    DB::destroy_database_for_real_dangerous("test");
    println!("Creating db");
    let db = DB::new("test").unwrap();
    println!("inserting dummy data");

    let mut uuids = vec![];

    let start_time = std::time::Instant::now();
    let count = 100000;
    for i in 0..count {
        if i % 1000 == 0 {
            println!("Inserted {} users, {}%", i, i as f64 / 1000.0);
        }
        let user: InternalUser = InternalUser::gen(&db);

        uuids.push(user.uuid.clone());
        user.save(&db)?;
    }
    let end_time = start_time.elapsed();
    println!("Inserted {} users in {:?}", count, end_time);
    println!("That's a user every {:?}", end_time / count as u32);
    println!(
        "Or, {} users per second",
        count as f64 / end_time.as_secs_f64()
    );

    //upsert main user
    let mut user: InternalUser = InternalUser::gen(&db);
    user.username = "asdf".to_string();
    user.hashed_password = hash("asdfasdf", 4)?;

    let mut ratings = Vec::with_capacity(uuids.len());
    for uuid in &uuids {
        //get rand bool
        let rand = rand::random::<bool>();
        match rand {
            true => {
                ratings.push(InternalRating::LikedBy(uuid.clone()));
            }
            false => {
                ratings.push(InternalRating::PassedBy(uuid.clone()));
            }
        }
    }

    user.ratings = ratings;

    //upsert chats
    for n in 0..5 {
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
            })
            .collect();

        let mut chat = InternalChat {
            uuid: InternalUuid::new(),
            users: vec![user.uuid.clone(), uuids[n].clone()],
            messages: messages.iter().map(|m| m.uuid.clone()).collect(),
            most_recent_message: messages.last().unwrap().content.clone(),
            unread: vec![0, 0],
            most_recent_sender: Some(uuids[n].clone()),
        };

        for message in messages {
            message.save(&mut chat, &db).unwrap();
        }
        user.chats.push(chat.uuid.clone());
        chat.save(&db)?;
    }

    user.save(&db).unwrap();

    return Ok(());
}
