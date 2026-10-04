use std::sync::{Mutex, OnceLock};

use matrix_sdk::Client;

use super::matrix::create_matrix_client;

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