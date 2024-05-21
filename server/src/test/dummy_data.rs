// #[test]
// fn insert_dummy_data() -> Result<(), Box<dyn std::error::Error>> {
//     use crate::internal_models::rating::Rated;
//     use crate::test::fake::FakeGen;
//     use fake::Fake;

//     use bcrypt::hash;

//     use crate::internal_models::{chat::Chat, message::Message, shared::UuidModel};

//     use crate::{
//         db::DB,
//         internal_models::{image::Image, user::User},
//         procedures::upsert_user::upsert_user,
//     };

//     println!("Destroying db");
//     DB::destroy_database_for_real_dangerous("test");
//     println!("Creating db");
//     let mut db = DB::new("test").unwrap();
//     println!("inserting dummy data");

//     let mut uuids = vec![];

//     let start_time = std::time::Instant::now();
//     let count = 100000;
//     for i in 0..count {
//         if i % 1000 == 0 {
//             println!("Inserted {} users, {}%", i, i as f64 / 1000.0);
//         }
//         let user: User = User::fake_gen(&true);

//         let images = vec![Image::default()];
//         upsert_user(&user, images, &mut db)?;
//         uuids.push(user.uuid);
//     }
//     let end_time = start_time.elapsed();
//     println!("Inserted {} users in {:?}", count, end_time);
//     println!("That's a user every {:?}", end_time / count as u32);
//     println!(
//         "Or, {} users per second",
//         count as f64 / end_time.as_secs_f64()
//     );

//     //upsert main user
//     let mut user: User = User::fake_gen(&true);
//     user.public.username = "asdf".to_string();
//     user.hashed_password = hash("asdfasdf", 4)?;
//     let mut images = vec![];
//     for _ in 0..5 {
//         images.push(Image::default());
//     }

//     let mut ratings = Vec::with_capacity(uuids.len());
//     for uuid in &uuids {
//         //get rand bool
//         let rand = rand::random::<bool>();
//         match rand {
//             true => {
//                 ratings.push(Rated::LikedBy(uuid.clone()));
//             }
//             false => {
//                 ratings.push(Rated::PassedBy(uuid.clone()));
//             }
//         }
//     }

//     user.ratings = ratings;

//     //upsert chats
//     for n in 0..5 {
//         let mut messages: Vec<Message> = (0..4)
//             .map(|n| Message {
//                 uuid: UuidModel::new(),
//                 sent_at: chrono::Utc::now().timestamp_millis() / 1000,
//                 author: if n % 2 == 0 {
//                     (&user).uuid.clone()
//                 } else {
//                     uuids[n].clone()
//                 },
//                 content: fake::faker::lorem::en::Sentence(1..2).fake(),
//                 image: None,
//                 image_type: None,
//                 reciever_read: false,
//             })
//             .collect();

//         let chat = Chat {
//             uuid: UuidModel::new(),
//             user1: (&user).uuid.clone(),
//             user2: uuids[n].clone(),
//             messages: messages.iter().map(|m| m.uuid.clone()).collect(),
//             most_recent_message: messages.last().unwrap().content.clone(),
//             user1_unread: 0,
//             user2_unread: 0,
//         };

//         db.insert_chat(&chat)?;
//         for message in &messages {
//             db.insert_message(message)?;
//         }

//         user.chats.push(chat.uuid.clone());
//         messages[0].image = Some(Image::default());
//         db.add_image_to_message_and_insert(&user, &chat, &messages[0])?;
//     }

//     upsert_user(&user, images, &mut db)?;

//     return Ok(());
// }
