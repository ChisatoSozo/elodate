use std::error::Error;

use super::shared::{Gen, InternalUuid, Save};

use crate::db::DB;

#[derive(Debug, Clone, rkyv::Archive, rkyv::Serialize, rkyv::Deserialize)]
#[archive(compare(PartialEq), check_bytes)]
pub struct InternalImage {
    pub uuid: InternalUuid<InternalImage>,
    pub content: Vec<u8>,
}

impl Gen<bool> for InternalImage {
    fn gen(_options: &bool) -> Self {
        InternalImage {
            uuid: InternalUuid::<InternalImage>::new(),
            #[allow(deprecated)]
            content: base64::decode(TEST_IMG_B64).unwrap(),
        }
    }
}

impl Save for InternalImage {
    fn save(self, db: &mut DB) -> Result<(), Box<dyn Error>> {
        db.write_object(&self.uuid, &self)?;
        Ok(())
    }
}

const TEST_IMG_B64: &str = "UklGRtYDAABXRUJQVlA4IMoDAACQEgCdASpAAEAAPp1AmkkoJa0kKhZtyLATiWIA0Puhx0ZSoQH5L3gHmAx1Xee671o94+f+S8qO8GVUZL4h9Ivj89CrtA9r/037A/SW/apA7TRTv2PBdXoV7ZEUUEvBvA8HFs/TcLQyFiDC6jV1tKkcqtOMwEGave6oMAK0SH4WD86nrZLamFYk/NzPEwjqfaDWgNxek+Ds9fUoNR6gAP7+exmkuMlT6WxKa+hW0t3Ne8k+13ZI12EFvZTF4ldw5UPmW1mK7QalNRRYx0h1cGLACc3VX0Brc3iNwtIX4GKQ0ErtdQ9AfIPd0lF7dyHDQ6CFWbkpCsP9OATR6x7P3ECg+7C7n4+XUsDjs7u7sMXmOiiS7XTNX0zgrzdvQXpMn9i3IZO8MVwJEmOKWJ7ocgWPduUAkP/44XaRwwstm11H5cJaI5NjyzM79sCPowIhHMVhPLqlmrs573IJ0gmjpcroTk02/vUiXaZ54Rzyu9cE/79hD00l+rCfU4IW/DZ/DQbsEfoh/zR5K2ZhksqGd1/+x4SN5RsR//8b0N86M4nvBusdG9Auqwoylo39Oc7d/0ofSuTrAyv1Z6Nw0/yGalwhrlkGT4S4Azfl4moP9fX/QMf8lXE/AUMd6x5r9FJ5vcboXSlkGyYolz5UdsRvv+apWTVQygSNB6Vn4bjTkDy3aVHMp/B9OzvY5tM4jdRgojUNxs8NTjTw+6EMtsTm6ecbIHXz27vd0A+ahYdfHXRfH5FfIvaMMxRH2mXMOWz17ASVahbbUFR6jmOVmFK4FZmzLLtL9DiRcOurpSwbcpDAQkLO88hjYlJ3MBvp5nf3MuehWjXK4QtPzTqnbWiXA7DPyLBJSN1fcBeyqOfjmy2iz7/G8q+hjPyoHz0t6rhtQCjEASLOg7/jK2E1MDKdGtEvH3kju2qx4G4xA6IyH/B2zHA8irYIGrQZMrnK95AgVnq3pLJ3zY7GDh8NySVnq/aIwV1rRLWZ71WaMS57ptSLn1xCl+c9aWgbq/9xB8ev/+B1wUcTY01AjP1vTZqJdAiDfB/ku6rZSHdkTSVL9txn7o6b9+JX4+jkSck42IeSqDZZjxaMmxpaTZt8W28S8s+htnge/rbcHcDdubmKPbtB5E7FBjRErEOZI450Fj94KWjCmtPNwNsIXKi/c3YhG93swxwgS2t8ZtEPRoX9+yv/bl8eBjaMNvi8yQEI2/pN+0M/ht+5I3YewBSY8x11NqvnHte+5kmk9pFEJYeF345ObAKvvzDSRW0ULEekG3D8TPLGKg8fxPDEAAAA";
