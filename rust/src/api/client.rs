use std::sync::{Mutex, OnceLock};

use matrix_sdk::{
    authentication::{matrix::MatrixSession, SessionTokens},
    ruma::{OwnedDeviceId, UserId},
    Client, SessionMeta,
};

use super::matrix::{create_matrix_client, AuthSession};


static MATRIX_CLIENT: OnceLock<Mutex<Option<Client>>> = OnceLock::new();

fn matrix_client() -> &'static Mutex<Option<Client>> {
    MATRIX_CLIENT.get_or_init(|| Mutex::new(None))
}

#[flutter_rust_bridge::frb]
pub async fn connect_matrix() -> Result<String, String> {
    let client = create_matrix_client()
        .await
        .map_err(|error| error.to_string())?;

    let homeserver = client.homeserver().to_string();

    let mut stored_client = matrix_client()
        .lock()
        .map_err(|error| error.to_string())?;

    *stored_client = Some(client);

    Ok(homeserver)
}

#[flutter_rust_bridge::frb]
pub async fn login_matrix(
    homeserver: String,
    username: String,
    password: String,
) -> Result<AuthSession, String> {
    let client = Client::builder()
        .homeserver_url(&homeserver)
        .build()
        .await
        .map_err(|error| error.to_string())?;

    let response = client
        .matrix_auth()
        .login_username(&username, &password)
        .initial_device_display_name("Nexa Desktop")
        .request_refresh_token()
        .send()
        .await
        .map_err(|error| error.to_string())?;

    let session = AuthSession {
        user_id: response.user_id.to_string(),
        device_id: response.device_id.to_string(),
        access_token: response.access_token,
        refresh_token: response.refresh_token,
    };

    let mut stored_client = matrix_client()
        .lock()
        .map_err(|error| error.to_string())?;

    *stored_client = Some(client);

    Ok(session)
}

#[flutter_rust_bridge::frb]
pub async fn restore_matrix_session(
    homeserver: String,
    user_id: String,
    device_id: String,
    access_token: String,
    refresh_token: Option<String>,
) -> Result<(), String> {
    let client = Client::builder()
        .homeserver_url(&homeserver)
        .build()
        .await
        .map_err(|error| error.to_string())?;

    let user_id = UserId::parse(&user_id)
        .map_err(|error| error.to_string())?;

    let device_id: OwnedDeviceId = device_id.as_str().into();

    let session = MatrixSession {
        meta: SessionMeta {
            user_id: user_id.to_owned(),
            device_id: device_id.to_owned(),
        },
        tokens: SessionTokens {
            access_token,
            refresh_token,
        },
    };

    client
        .restore_session(session)
        .await
        .map_err(|error| error.to_string())?;

    let mut stored_client = matrix_client()
        .lock()
        .map_err(|error| error.to_string())?;

    *stored_client = Some(client);

    Ok(())
}

pub(crate) fn get_authenticated_client() -> Result<Client, String> {
    let stored_client = matrix_client()
        .lock()
        .map_err(|error| error.to_string())?;

    stored_client
        .as_ref()
        .cloned()
        .ok_or_else(|| "Matrix client is not authenticated".to_string())
}