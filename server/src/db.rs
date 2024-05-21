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
use std::path::Path;

use crate::models::internal_models::{
    internal_preferences::TOTAL_PREFERENCES_CARDINALITY, shared::InternalUuid,
};
use crate::vec::search_linear::LinearSearch;
use crate::vec::shared::VectorSearch;

pub const SCRATCH_SPACE_SIZE: usize = 8192;
pub type DefaultSerializer = AllocSerializer<SCRATCH_SPACE_SIZE>;

pub struct DB {
    pub store: Store,
    pub vec_index: LinearSearch<TOTAL_PREFERENCES_CARDINALITY>,
    pub path: String,
}

impl DB {
    pub fn new(path: &str) -> Result<Self, kv::Error> {
        println!("Opening database");
        let db_path = "db/".to_owned() + path;
        let vector_db_path = db_path.clone() + "/vec_index.bin";
        let vector_search = LinearSearch::load_from_file(&vector_db_path).unwrap();
        let cfg = Config::new(db_path.clone() + "/kv");
        let store = Store::new(cfg)?;
        Ok(DB {
            store,
            vec_index: vector_search,
            path: db_path,
        })
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
        key: &InternalUuid<T>,
        object: &T,
    ) -> Result<(), Box<dyn std::error::Error>>
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
        let bucket = self.store.bucket::<Raw, Raw>(Some("object_storage"))?;
        let key_raw = Raw::from(key.id.as_bytes());
        let value_raw = Raw::from(bytes.as_slice());
        bucket.set(&key_raw, &value_raw)?;
        Ok(())
    }

    pub fn read_object<T>(
        &self,
        key: &InternalUuid<T>,
    ) -> Result<Option<T>, Box<dyn std::error::Error>>
    where
        T: Archive,
        for<'a> T::Archived: rkyv::CheckBytes<DefaultValidator<'a>> + Deserialize<T, Infallible>,
    {
        let bucket = self.store.bucket::<Raw, Raw>(Some("object_storage"))?;
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
}
