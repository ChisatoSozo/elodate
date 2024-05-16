use crate::models::chat::Chat;
use crate::models::message::Message;
use crate::models::preference::PREFERENCE_LENGTH;
use crate::models::user::User;
use crate::mokuroku::lib::{Database, Document, Emitter, Error};

use crate::vec::search_linear::LinearSearch;
use crate::vec::shared::VectorSearch;
use std::path::Path;

pub struct DB {
    pub db: Database,
    pub vec_index: LinearSearch<PREFERENCE_LENGTH>,
    pub path: String,
}

pub fn get_any_from_key<T: Document>(
    view: &str,
    key: &[u8],
    db: &mut Database,
) -> Result<Vec<T>, Error> {
    //key to doc_id parse
    let doc_ids = {
        let mut result = db.query_exact(view, key)?;
        let mut doc_ids = Vec::new();
        while let Some(document) = result.next() {
            doc_ids.push(document.doc_id);
        }
        doc_ids
    };
    let mut documents = Vec::new();
    for doc_id in doc_ids {
        let document: Option<T> = db.get(doc_id)?;
        match document {
            Some(document) => documents.push(document),
            None => {}
        }
    }
    Ok(documents)
}

pub fn get_single_from_key<T: Document>(
    view: &str,
    key: &[u8],
    db: &mut Database,
) -> Result<T, Error> {
    //key to doc_id parse
    let doc_id = {
        let mut result = db.query_exact(view, key)?;
        let first = result.next();
        match first {
            Some(result) => Ok(result.doc_id),
            None => Err(Error::Serde("No document found".to_owned())),
        }
    }?;
    let document: Option<T> = db.get(doc_id)?;
    match document {
        Some(document) => Ok(document),
        None => Err(Error::Serde("No document found".to_owned())),
    }
}

impl DB {
    pub fn new(path: &str) -> Self {
        println!("Opening database");
        let db_path = "db/".to_owned() + path;
        let vector_db_path = db_path.clone() + "/vec_index.bin";
        let vector_search = LinearSearch::load_from_file(&vector_db_path).unwrap();
        let views: Vec<String> = VIEWS.to_vec().into_iter().map(|s| s.to_owned()).collect();
        let dbase = Database::open_default(Path::new(&db_path), views, Box::new(mapper)).unwrap();
        DB {
            db: dbase,
            path: db_path,
            vec_index: vector_search,
        }
    }

    pub fn persist(&self) {
        self.vec_index
            .save_to_file(&(self.path.to_string() + "/vec_index.bin"))
            .unwrap();
    }

    pub fn destroy_database_for_real_dangerous(path: &str) {
        if !Path::new(&("db/".to_owned() + path)).exists() {
            return;
        }
        std::fs::remove_dir_all("db/".to_owned() + path).unwrap();
    }

    pub fn get_flag(&self, key: &str) -> bool {
        let key = b"flag/"
            .to_vec()
            .into_iter()
            .chain(key.as_bytes().to_vec().into_iter())
            .collect::<Vec<u8>>();
        let result = self.db.db.get(key);
        match result {
            Ok(Some(_)) => true,
            Ok(None) => false,
            Err(_) => false,
        }
    }

    pub fn set_flag(&mut self, key_in: &str, value: bool) {
        let key = b"flag/"
            .to_vec()
            .into_iter()
            .chain(key_in.as_bytes().to_vec().into_iter())
            .collect::<Vec<u8>>();
        if value {
            self.db.db.put(key, "t").unwrap();
        } else {
            if self.get_flag(key_in) {
                self.db.db.delete(key).unwrap();
            }
        }
    }

    // Other database-related functions
}

const VIEWS: [&str; 5] = ["uuid", "code", "user1", "user2", "username"];

fn mapper(key: &[u8], value: &[u8], view: &str, emitter: &Emitter) -> Result<(), Error> {
    if &key[..5] == b"user/".as_ref() {
        let user = User::from_bytes(key, value)?;
        user.map(view, emitter)?;
        Ok(())
    } else if &key[..5] == b"chat/".as_ref() {
        let chat = Chat::from_bytes(key, value)?;
        chat.map(view, emitter)?;
        Ok(())
    } else if &key[..8] == b"message/".as_ref() {
        let message = Message::from_bytes(key, value)?;
        message.map(view, emitter)?;
        Ok(())
    } else if &key[..5] == b"flag/".as_ref() {
        Ok(())
    } else {
        let key_string = std::str::from_utf8(key).unwrap();
        let value_string = std::str::from_utf8(value).unwrap();
        Err(Error::Serde(format!(
            "Unknown key: {:?}\n value: {:?}\n view: {:?}",
            key_string, value_string, view
        )))
    }
}
