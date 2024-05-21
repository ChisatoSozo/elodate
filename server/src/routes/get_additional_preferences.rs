// use actix_web::Error;

// use paperclip::actix::{api_v2_operation, get, web::Json};

// use crate::models::internal_models::internal_preferences::{
//     PreferenceConfig, ADDITIONAL_PREFERENCES,
// };

// #[api_v2_operation]
// #[get("/get_additional_preferences")]
// pub async fn get_additional_preferences() -> Result<Json<Vec<PreferenceConfig>>, Error> {
//     Ok(Json(
//         ADDITIONAL_PREFERENCES
//             .iter()
//             .map(|p| {
//                 p.get_public()
//                 // Provide type annotation for collect method
//             })
//             .collect::<Vec<AdditionalPreferencePublic>>(),
//     ))
// }
