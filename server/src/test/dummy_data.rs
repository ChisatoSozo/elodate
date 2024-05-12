#[actix_web::test]
async fn insert_dummy_data() -> Result<(), Box<dyn std::error::Error>> {
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

    let count = 1000;
    for n in 0..count {
        println!("Inserting dummy data {}/{}", n, count);
        let user: User = Faker.fake();
        let mut images = vec![];
        for _ in 0..5 {
            images.push(Image::default());
        }
        upsert_user(&user, images, &mut db).await?;
    }

    return Ok(());
}
