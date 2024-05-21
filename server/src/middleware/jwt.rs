use actix_web::HttpMessage;
use jsonwebtoken::{decode, Algorithm, DecodingKey, EncodingKey, Validation};
use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize)]
struct Claims {
    uuid: String,
    exp: usize,
}

use std::future::{ready, Ready};

use actix_web::{
    dev::{forward_ready, Service, ServiceRequest, ServiceResponse, Transform},
    Error,
};
use futures_util::future::LocalBoxFuture;

use crate::{
    models::internal_models::{internal_user::InternalUser, shared::InternalUuid},
    JSON_SPEC_PATH,
};

// There are two steps in middleware processing.
// 1. Middleware initialization, middleware factory gets called with
//    next service in chain as parameter.
// 2. Middleware's call method gets called with normal request.
pub struct Jwt;

// Middleware factory is `Transform` trait
// `S` - type of the next service
// `B` - type of response's body
impl<S, B> Transform<S, ServiceRequest> for Jwt
where
    S: Service<ServiceRequest, Response = ServiceResponse<B>, Error = Error>,
    S::Future: 'static,
    B: 'static,
{
    type Response = ServiceResponse<B>;
    type Error = Error;
    type InitError = ();
    type Transform = JwtMiddleware<S>;
    type Future = Ready<Result<Self::Transform, Self::InitError>>;

    fn new_transform(&self, service: S) -> Self::Future {
        ready(Ok(JwtMiddleware { service }))
    }
}

pub struct JwtMiddleware<S> {
    service: S,
}

const NOAUTH_PATHS: [&str; 4] = ["/login", "/signup", "/check_username", JSON_SPEC_PATH];

impl<S, B> Service<ServiceRequest> for JwtMiddleware<S>
where
    S: Service<ServiceRequest, Response = ServiceResponse<B>, Error = Error>,
    S::Future: 'static,
    B: 'static,
{
    type Response = ServiceResponse<B>;
    type Error = Error;
    type Future = LocalBoxFuture<'static, Result<Self::Response, Self::Error>>;

    forward_ready!(service);

    fn call(&self, req: ServiceRequest) -> Self::Future {
        if NOAUTH_PATHS.contains(&req.path()) {
            return Box::pin(self.service.call(req));
        }

        if req.method() == "OPTIONS" {
            return Box::pin(self.service.call(req));
        }

        let auth_header = req.headers().get("Authorization");

        match auth_header {
            Some(header_value) => match header_value.to_str() {
                Ok(auth_str) if auth_str.starts_with("Bearer ") => {
                    let token = &auth_str[7..]; // Extract the actual token
                    let jwk = include_str!("key/jwk.pem.pub"); // Load your key here
                    let decoding_key = match DecodingKey::from_rsa_pem(jwk.as_bytes()) {
                        Ok(key) => key,
                        Err(e) => {
                            println!("Failed to decode key {:?}", e);
                            return Box::pin(async {
                                Err(Error::from(actix_web::error::ErrorUnauthorized(
                                    "Invalid key format",
                                )))
                            });
                        }
                    };
                    let validation = Validation::new(Algorithm::RS256);

                    match decode::<Claims>(token, &decoding_key, &validation) {
                        Ok(claims) => {
                            if claims.claims.exp < chrono::Utc::now().timestamp() as usize {
                                println!("Token expired");
                                return Box::pin(async {
                                    Err(Error::from(actix_web::error::ErrorUnauthorized(
                                        "Token expired",
                                    )))
                                });
                            }
                            let uuid: InternalUuid<InternalUser> = claims.claims.uuid.into();

                            {
                                let mut ext = req.extensions_mut();
                                ext.insert(uuid);
                            }
                            Box::pin(self.service.call(req))
                        }
                        Err(err) => {
                            println!("Failed to decode token {:?}", err);
                            Box::pin(async move {
                                Err(Error::from(actix_web::error::ErrorUnauthorized(
                                    err.to_string(),
                                )))
                            })
                        }
                    }
                }
                e => {
                    println!("Failed to parse auth header {:?}", e);
                    Box::pin(async {
                        Err(Error::from(actix_web::error::ErrorUnauthorized(
                            "Invalid token format",
                        )))
                    })
                }
            },
            None => {
                println!("Missing token");
                Box::pin(async {
                    Err(Error::from(actix_web::error::ErrorUnauthorized(
                        "Missing token",
                    )))
                })
            }
        }
    }
}

pub fn make_jwt(uuid: &InternalUuid<InternalUser>) -> Result<String, jsonwebtoken::errors::Error> {
    //make it expire in 2 hours
    let claims = Claims {
        uuid: uuid.id.clone(),
        exp: (chrono::Utc::now() + chrono::Duration::hours(2)).timestamp() as usize,
    };

    let pem_data = include_str!("key/jwk.pem.priv"); // Load your key here
    let encoding_key = EncodingKey::from_rsa_pem(pem_data.as_bytes())?;
    jsonwebtoken::encode(
        &jsonwebtoken::Header::new(Algorithm::RS256),
        &claims,
        &encoding_key,
    )
}
