use std::fs;

use paperclip::actix::{
    api_v2_operation, post,
    web::{self, Json},
    Apiv2Schema,
};
use serde::Deserialize;
use uuid::Uuid;

use crate::{
    db::DB,
    models::{
        api_models::shared::ApiUuid,
        internal_models::{
            internal_chat::InternalChat, internal_user::InternalUser, shared::InternalUuid,
        },
    },
};

#[derive(Debug, Deserialize, Apiv2Schema)]
struct ReportInput {
    is_violation: bool,
    content: String,
    imageb64: String,
    user_uuid: Option<ApiUuid<InternalUser>>,
    chat: Option<ApiUuid<InternalChat>>,
    platform: Option<String>,
}

#[api_v2_operation]
#[post("/report")]
fn report(
    db: web::Data<DB>,
    _: web::HttpRequest,
    body: Json<ReportInput>,
) -> Result<Json<bool>, actix_web::Error> {
    //decode image64
    #[allow(deprecated)]
    let bytes = base64::decode(&body.imageb64).map_err(|e| {
        log::error!("Failed to decode image {:?}", e);
        std::io::Error::new(std::io::ErrorKind::Other, "Failed to decode image")
    })?;
    //autodetect format and convert to jpg
    let img = image::load_from_memory(&bytes)
        .map_err(|e| {
            log::error!("Failed to load image {:?}", e);
            std::io::Error::new(std::io::ErrorKind::Other, "Failed to load image")
        })?
        .to_rgb8();
    let mut buf = Vec::new();
    image::codecs::jpeg::JpegEncoder::new(&mut buf)
        .encode(
            &img,
            img.width(),
            img.height(),
            image::ExtendedColorType::Rgb8,
        )
        .map_err(|e| {
            log::error!("Failed to encode image {:?}", e);
            std::io::Error::new(std::io::ErrorKind::Other, "Failed to encode image")
        })?;
    //save image
    let report_uuid = Uuid::new_v4();
    //save image and text content to folder report/report_uuid/*

    let report_base_folder = if body.is_violation {
        "report/violation"
    } else {
        "report/bug"
    };

    //if folder does not exist, create it
    fs::create_dir_all(format!("{}/{}", report_base_folder, report_uuid))?; //create folder
    fs::write(
        format!("{}/{}/report.txt", report_base_folder, report_uuid),
        body.content.clone(),
    )?; //write text content
    fs::write(
        format!("{}/{}/report.jpg", report_base_folder, report_uuid),
        buf,
    )?; //write image content

    //write platform type to report folder
    fs::write(
        format!("{}/{}/platform.txt", report_base_folder, report_uuid),
        body.platform.clone().unwrap_or("unknown".to_string()),
    )?;

    if let Some(user_uuid) = &body.user_uuid {
        let internal_uuid: InternalUuid<InternalUser> = user_uuid.clone().into();
        let user = internal_uuid.load(&db)?;
        let user = match user {
            Some(user) => user,
            None => {
                return Err(actix_web::error::ErrorNotFound(
                    "User target of report not found",
                ));
            }
        };
        let images = user
            .images
            .clone()
            .into_iter()
            .map(|i| i.load(&db))
            .collect::<Result<Option<Vec<_>>, _>>()?;
        let images = match images {
            Some(images) => images,
            None => return Err(actix_web::error::ErrorNotFound("Images not found")),
        };
        //write each to report folder
        for (i, image) in images.iter().enumerate() {
            fs::write(
                format!(
                    "{}/{}/user_image_{}.jpg",
                    report_base_folder, report_uuid, i
                ),
                image.content.clone(),
            )?;
        }
    };

    //is there a chat?
    if let Some(chat_uuid) = &body.chat {
        let internal_uuid: InternalUuid<InternalChat> = chat_uuid.clone().into();
        let chat = internal_uuid.load(&db)?;
        let chat = match chat {
            Some(chat) => chat,
            None => {
                return Err(actix_web::error::ErrorNotFound("Chat not found"));
            }
        };
        let messages = chat
            .messages
            .clone()
            .into_iter()
            .map(|m| m.load(&db))
            .collect::<Result<Option<Vec<_>>, _>>()?;
        let messages = match messages {
            Some(messages) => messages,
            None => return Err(actix_web::error::ErrorNotFound("Messages not found")),
        };
        //write chat to chat.json, and make each message a line in messages.txt
        fs::write(
            format!("{}/{}/chat.json", report_base_folder, report_uuid),
            serde_json::to_string(&chat)?,
        )?;
        fs::write(
            format!("{}/{}/messages.txt", report_base_folder, report_uuid),
            messages
                .iter()
                .map(|m| m.pprint())
                .collect::<Result<Vec<_>, _>>()?
                .join("\n"),
        )?;
        //write each message to message_{message_id}.json
        for (i, message) in messages.iter().enumerate() {
            fs::write(
                format!("{}/{}/message_{}.json", report_base_folder, report_uuid, i),
                serde_json::to_string(&message)?,
            )?;
        }
        //for each message, if it has an image, write the image to message_{message_id}.jpg
        for (i, message) in messages.iter().enumerate() {
            if let Some(image) = &message.image {
                let image = image.load(&db)?;
                let image = match image {
                    Some(image) => image,
                    None => {
                        return Err(actix_web::error::ErrorNotFound("Image not found"));
                    }
                };
                fs::write(
                    format!("{}/{}/message_{}.jpg", report_base_folder, report_uuid, i),
                    image.content.clone(),
                )?;
            }
        }
    };

    return Ok(Json(true));
}
