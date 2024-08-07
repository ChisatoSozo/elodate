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
    error::Error,
    mem,
    path::Path,
    sync::{Arc, Mutex},
};

use crate::models::internal_models::{
    internal_prefs_config::PREFS_CARDINALITY,
    internal_user::InternalUser,
    shared::{GetBbox, GetVector, Insertable, InternalUuid},
};
use crate::vec::search_linear::LinearSearch;
use crate::vec::shared::VectorSearch;

pub const SCRATCH_SPACE_SIZE: usize = 8192;
pub type DefaultSerializer = AllocSerializer<SCRATCH_SPACE_SIZE>;

pub struct PubStore {
    pub config: Config,
    pub db: sled::Db,
}

pub fn flush(store: &Store) -> Result<usize, sled::Error> {
    let public_struct = unsafe { mem::transmute::<_, &PubStore>(store) };
    public_struct.db.flush()
}

pub struct DB {
    pub store: Store,
    pub vec_index: Arc<Mutex<LinearSearch<PREFS_CARDINALITY>>>,
    pub path: String,
}

impl DB {
    pub fn new(path: &str) -> Result<Self, kv::Error> {
        log::info!("Opening database");
        let db_path = "db/".to_owned() + path;

        let cfg = Config::new(db_path.clone() + "/kv");
        let store = Store::new(cfg)?;

        let vector_search = LinearSearch::new();
        let db = DB {
            store,
            vec_index: Arc::new(Mutex::new(vector_search)),
            path: db_path,
        };

        let users = db.iter_obj::<InternalUser>()?;

        for user in users {
            let user = user.unwrap();
            let mut vec_index = db.vec_index.lock().unwrap();
            let bbox = user.prefs.get_bbox();
            let vec = user.props.get_vector();
            if user.published {
                vec_index.add(&vec, &user.uuid.id);
                vec_index.add_bbox(&bbox, &user.uuid.id);
            } else {
                log::info!("User not published, not adding to vec index")
            }
        }

        Ok(db)
    }

    pub fn destroy_database_for_real_dangerous(path: &str) {
        if !Path::new(&("db/".to_owned() + path)).exists() {
            return;
        }
        std::fs::remove_dir_all("db/".to_owned() + path).unwrap();
    }

    pub fn flush(&self) -> Result<usize, sled::Error> {
        flush(&self.store)
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

    pub fn get_version<T: Insertable>(&self) -> Result<u64, kv::Error> {
        let bucket = self.store.bucket::<String, String>(Some("version"))?;
        let key = T::bucket();
        let result = bucket.get(&key.to_string())?;
        match result {
            Some(value) => Ok(value.parse::<u64>().unwrap()),
            None => Ok(0),
        }
    }

    pub fn set_version<T: Insertable>(&self, new_version: usize) -> Result<(), Box<dyn Error>> {
        let version = self.get_version::<T>()?;
        //check if new version is greater than current version by 1 or equal
        if new_version as u64 != version + 1 && new_version as u64 != version {
            return Err(format!(
                "Invalid version, version must be {} or {}",
                version + 1,
                version
            ))?;
        }
        let bucket = self.store.bucket::<String, String>(Some("version"))?;
        let key = T::bucket();
        bucket.set(&key.to_string(), &(new_version).to_string())?;
        Ok(())
    }

    pub fn write_index<T: Insertable>(
        &self,
        view: &str,
        value: &String,
        uuid: &InternalUuid<T>,
    ) -> Result<(), kv::Error> {
        log::trace!(
            "Writing index value {:?} to view {:?} with uuid {:?}",
            value,
            view,
            uuid.id
        );
        let bucket = self.store.bucket::<String, String>(Some(view))?;
        bucket.set(value, &uuid.id)?;
        Ok(())
    }

    pub fn delete_index(&self, view: &str, value: &String) -> Result<(), kv::Error> {
        let bucket = self.store.bucket::<String, String>(Some(view))?;
        bucket.remove(value)?;
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
    ) -> Result<InternalUuid<T>, Box<dyn std::error::Error>>
    where
        T: Serialize<
                CompositeSerializer<
                    AlignedSerializer<AlignedVec>,
                    FallbackScratch<HeapScratch<SCRATCH_SPACE_SIZE>, AllocScratch>,
                    SharedSerializeMap,
                >,
            > + Insertable,
    {
        let version = self.get_version::<T>()?;
        if version != T::version() {
            return Err(format!(
                "Version mismatch for object {:?} of type {:?}, object has {:?}, db has {:?}",
                key.id,
                T::bucket(),
                T::version(),
                version
            ))?;
        }
        let mut serializer = DefaultSerializer::default();
        serializer.serialize_value(object).unwrap();
        let bytes = serializer.into_serializer().into_inner();
        let bucket = self.store.bucket::<Raw, Raw>(Some(T::bucket()))?;
        let key_raw = Raw::from(key.id.as_bytes());
        let value_raw = Raw::from(bytes.as_slice());
        let contains = bucket.contains(&key_raw)?;
        if !contains {
            log::trace!(
                "Writing new object to db: {:?}, it's a {:?}",
                key.id,
                T::bucket()
            );
        }
        bucket.set(&key_raw, &value_raw)?;
        Ok(key.id.clone().into())
    }

    pub fn read_object<T>(
        &self,
        key: &InternalUuid<T>,
    ) -> Result<Option<T>, Box<dyn std::error::Error>>
    where
        T: Archive + Insertable,
        for<'a> T::Archived: rkyv::CheckBytes<DefaultValidator<'a>> + Deserialize<T, Infallible>,
    {
        let bucket = T::bucket();
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
    ) -> Result<impl Iterator<Item = Result<T, Box<dyn std::error::Error>>>, kv::Error>
    where
        T: Archive + Insertable,
        for<'a> T::Archived: rkyv::CheckBytes<DefaultValidator<'a>> + Deserialize<T, Infallible>,
    {
        let bucket = self.store.bucket::<Raw, Raw>(Some(T::bucket()))?;
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
    ) -> Result<Option<std::convert::Infallible>, Box<dyn std::error::Error>>
    where
        T: Archive,
        for<'a> T::Archived: rkyv::CheckBytes<DefaultValidator<'a>> + Deserialize<T, Infallible>,
    {
        let bucket = self.store.bucket::<Raw, Raw>(Some("object_storage"))?;
        let key_raw = Raw::from(key.id.as_bytes());
        let result = bucket.remove(&key_raw)?;
        match result {
            Some(_) => return Err("This should never happen, delete_object::db".into()),
            None => return Ok(None),
        };
    }

    pub fn object_exists<T>(&self, key: &InternalUuid<T>) -> Result<bool, kv::Error> {
        let bucket = self.store.bucket::<Raw, Raw>(Some("object_storage"))?;
        let key_raw = Raw::from(key.id.as_bytes());
        let result = bucket.contains(&key_raw)?;
        Ok(result)
    }
}
