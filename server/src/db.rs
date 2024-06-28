use kv::{Config, Raw, Store};
use rkyv::{
    ser::{
        serializers::{
            AlignedSerializer, AllocScratch, AllocSerializer, CompositeSerializer, FallbackScratch,
            HeapScratch, SharedSerializeMap,
        },
        Serializer,
    },
    validation::validators::DefaultValidator,
    AlignedVec, Archive, Deserialize, Infallible, Serialize,
};
use std::{
    path::Path,
    sync::{Arc, Mutex},
};

use crate::models::internal_models::{
    internal_prefs_config::PREFS_CARDINALITY,
    internal_user::InternalUser,
    shared::{Bucket, GetBbox, GetVector, InternalUuid},
};
use crate::vec::search_linear::LinearSearch;
use crate::vec::shared::VectorSearch;

pub const SCRATCH_SPACE_SIZE: usize = 8192;
pub type DefaultSerializer = AllocSerializer<SCRATCH_SPACE_SIZE>;

pub struct DB {
    pub store: Store,
    pub vec_index: Arc<Mutex<LinearSearch<PREFS_CARDINALITY>>>,
    pub path: String,
}

impl DB {
    pub fn new(path: &str) -> Result<Self, kv::Error> {
        println!("Opening database");
        let db_path = "db/".to_owned() + path;

        let cfg = Config::new(db_path.clone() + "/kv");
        let store = Store::new(cfg)?;

        let vector_search = LinearSearch::new();
        let db = DB {
            store,
            vec_index: Arc::new(Mutex::new(vector_search)),
            path: db_path,
        };

        let users = db.iter_obj::<InternalUser>("users");

        let users = match users {
            Ok(users) => users,
            Err(_) => {
                println!("No users found in database");
                return Ok(db);
            }
        };

        for user in users {
            let user = user.unwrap();
            let mut vec_index = db.vec_index.lock().unwrap();
            let bbox = user.prefs.get_bbox();
            let vec = user.props.get_vector();
            vec_index.add(&vec, &user.uuid.id);
            vec_index.add_bbox(&bbox, &user.uuid.id);
        }

        Ok(db)
    }

    pub fn destroy_database_for_real_dangerous(path: &str) {
        if !Path::new(&("db/".to_owned() + path)).exists() {
            return;
        }
        std::fs::remove_dir_all("db/".to_owned() + path).unwrap();
    }

    pub fn get_flag(&self, key: &str) -> Result<bool, Box<dyn std::error::Error>> {
        let bucket = self.store.bucket::<Raw, String>(Some("raw"))?;
        let key = key.as_bytes();
        let key_raw = Raw::from(key);
        let result = bucket.get(&key_raw)?;
        match result {
            Some(value) => match value.as_str() {
                "t" => Ok(true),
                "f" => Ok(false),
                _ => Err("Invalid flag value".into()),
            },
            None => Ok(false),
        }
    }

    pub fn set_flag(&mut self, key_in: &str, value: bool) -> Result<(), kv::Error> {
        let key = key_in.as_bytes();
        let key_raw = Raw::from(key);
        let value_str = if value { "t" } else { "f" };
        let bucket = self.store.bucket::<Raw, String>(Some("raw"))?;
        bucket.set(&key_raw, &value_str.to_string())?;
        Ok(())
    }

    pub fn get_version<T: Bucket>(&self) -> Result<u64, kv::Error> {
        let bucket = self.store.bucket::<String, String>(Some("version"))?;
        let key = T::bucket();
        let result = bucket.get(&key.to_string())?;
        match result {
            Some(value) => Ok(value.parse::<u64>().unwrap()),
            None => Ok(0),
        }
    }

    pub fn increment_version<T: Bucket>(&self) -> Result<(), kv::Error> {
        let version = self.get_version::<T>()?;
        let bucket = self.store.bucket::<String, String>(Some("version"))?;
        let key = T::bucket();
        bucket.set(&key.to_string(), &(version + 1).to_string())?;
        Ok(())
    }

    pub fn write_index<T>(
        &self,
        view: &str,
        value: &String,
        uuid: &InternalUuid<T>,
    ) -> Result<(), kv::Error> {
        let bucket = self.store.bucket::<String, String>(Some(view))?;
        bucket.set(value, &uuid.id)?;
        Ok(())
    }

    pub fn read_index<T>(
        &self,
        view: &str,
        value: &String,
    ) -> Result<Option<InternalUuid<T>>, kv::Error> {
        let bucket = self.store.bucket::<String, String>(Some(view))?;
        let result = bucket.get(value)?;
        match result {
            Some(value_raw) => Ok(Some(value_raw.into())),
            None => Ok(None),
        }
    }

    pub fn write_object<T>(
        &self,
        bucket: &str,
        key: &InternalUuid<T>,
        object: &T,
    ) -> Result<InternalUuid<T>, Box<dyn std::error::Error>>
    where
        T: Serialize<
            CompositeSerializer<
                AlignedSerializer<AlignedVec>,
                FallbackScratch<HeapScratch<SCRATCH_SPACE_SIZE>, AllocScratch>,
                SharedSerializeMap,
            >,
        >,
    {
        let mut serializer = DefaultSerializer::default();
        serializer.serialize_value(object).unwrap();
        let bytes = serializer.into_serializer().into_inner();
        let bucket = self.store.bucket::<Raw, Raw>(Some(bucket))?;
        let key_raw = Raw::from(key.id.as_bytes());
        let value_raw = Raw::from(bytes.as_slice());
        bucket.set(&key_raw, &value_raw)?;
        Ok(key.id.clone().into())
    }

    pub fn read_object<T>(
        &self,
        bucket: &str,
        key: &InternalUuid<T>,
    ) -> Result<Option<T>, Box<dyn std::error::Error>>
    where
        T: Archive,
        for<'a> T::Archived: rkyv::CheckBytes<DefaultValidator<'a>> + Deserialize<T, Infallible>,
    {
        let bucket = self.store.bucket::<Raw, Raw>(Some(bucket))?;
        let key_raw = Raw::from(key.id.as_bytes());
        let result = bucket.get(&key_raw)?;
        let value_raw = match result {
            Some(value_raw) => value_raw,
            None => return Ok(None),
        };

        // Ensuring value_raw is scoped to the check_archived_root and deserialize
        {
            let archived = rkyv::check_archived_root::<T>(&value_raw[..])?;
            let deserialized: T = archived.deserialize(&mut Infallible)?;
            Ok(Some(deserialized))
        }
    }

    pub fn iter_obj<T>(
        &self,
        bucket: &str,
    ) -> Result<impl Iterator<Item = Result<T, Box<dyn std::error::Error>>>, kv::Error>
    where
        T: Archive,
        for<'a> T::Archived: rkyv::CheckBytes<DefaultValidator<'a>> + Deserialize<T, Infallible>,
    {
        let bucket = self.store.bucket::<Raw, Raw>(Some(bucket))?;
        let iter = bucket.iter().map(move |elem| {
            let item = elem.map_err(|e| Box::new(e) as Box<dyn std::error::Error>)?;
            let value: Raw = item.value()?;
            let archived = rkyv::check_archived_root::<T>(&value[..])
                .map_err(|e| Box::new(e) as Box<dyn std::error::Error>)?;
            let deserialized: T = archived
                .deserialize(&mut Infallible)
                .map_err(|e| Box::new(e) as Box<dyn std::error::Error>)?;
            Ok(deserialized)
        });

        Ok(iter)
    }

    pub fn delete_object<T>(
        &self,
        key: &InternalUuid<T>,
    ) -> Result<Option<T>, Box<dyn std::error::Error>>
    where
        T: Archive,
        for<'a> T::Archived: rkyv::CheckBytes<DefaultValidator<'a>> + Deserialize<T, Infallible>,
    {
        let bucket = self.store.bucket::<Raw, Raw>(Some("object_storage"))?;
        let key_raw = Raw::from(key.id.as_bytes());
        let result = bucket.remove(&key_raw)?;
        let value_raw = match result {
            Some(value_raw) => value_raw,
            None => return Ok(None),
        };

        // Ensuring value_raw is scoped to the check_archived_root and deserialize
        {
            let archived = rkyv::check_archived_root::<T>(&value_raw[..])?;
            let deserialized: T = archived.deserialize(&mut Infallible)?;
            Ok(Some(deserialized))
        }
    }

    pub fn object_exists<T>(&self, key: &InternalUuid<T>) -> Result<bool, kv::Error> {
        let bucket = self.store.bucket::<Raw, Raw>(Some("object_storage"))?;
        let key_raw = Raw::from(key.id.as_bytes());
        let result = bucket.contains(&key_raw)?;
        Ok(result)
    }
}
