#[actix_web::test]
async fn insert_dummy_data() -> Result<(), Box<dyn std::error::Error>> {
    use crate::models::user::Preference;
    use bcrypt::hash;
    use fake::faker;

    use crate::models::{chat::Chat, message::Message, shared::UuidModel};
    use fake::{Fake, Faker};

    use crate::{
        db::DB,
        models::{image::Image, user::User},
        procedures::upsert_user::upsert_user,
    };

    println!("Destroying db");
    DB::destroy_database_for_real_dangerous("test");
    println!("Creating db");
    let mut db = DB::new("test");
    println!("inserting dummy data");

    let mut uuids = vec![];

    let count = 10;
    for n in 0..count {
        println!("Inserting dummy data {}/{}", n, count);
        let mut user: User = Faker.fake();
        user.public.preference = Preference::default();
        println!("User: {:?}", user.public.description);

        let mut images = vec![];
        for _ in 0..5 {
            images.push(Image::default());
        }
        upsert_user(&user, images, &mut db).await?;
        uuids.push(user.uuid);
    }

    //upsert main user
    let mut user: User = Faker.fake();
    user.hashed_password = hash("asdfasdf", 4)?;
    user.public.username = "asdf".to_string();
    user.chats = vec![];
    user.seen = std::collections::HashSet::new();
    user.ratings = vec![];
    user.elo = 1000;
    user.public.preference = Preference::default();
    let mut images = vec![];
    for _ in 0..5 {
        images.push(Image::default());
    }

    //upsert chats
    for n in 0..5 {
        let messages: Vec<Message> = (0..4)
            .map(|n| Message {
                uuid: UuidModel::new(),
                sent_at: chrono::Utc::now().timestamp_millis() / 1000,
                author: if n % 2 == 0 {
                    (&user).uuid.clone()
                } else {
                    uuids[n].clone()
                },
                content: faker::lorem::en::Sentence(1..2).fake(),
                image: None,
                image_type: None,
            })
            .collect();

        let chat = Chat {
            uuid: UuidModel::new(),
            user1: (&user).uuid.clone(),
            user2: uuids[n].clone(),
            messages: messages.iter().map(|m| m.uuid.clone()).collect(),
        };

        db.insert_chat(&chat)?;
        for message in &messages {
            db.insert_message(message)?;
        }

        user.chats.push(chat.uuid.clone());
        db.add_image_to_message(&user, &chat, &messages[0], &Image::default())?;
    }

    upsert_user(&user, images, &mut db).await?;

    return Ok(());
}
