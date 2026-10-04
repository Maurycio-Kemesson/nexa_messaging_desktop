use std::sync::{Mutex, OnceLock};

use matrix_sdk::Client;

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