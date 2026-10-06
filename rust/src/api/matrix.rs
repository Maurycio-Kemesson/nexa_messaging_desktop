use matrix_sdk::Client;

#[derive(Debug, Clone)]
pub struct AuthSession {
    pub user_id: String,
    pub device_id: String,
    pub access_token: String,
    pub refresh_token: Option<String>,
}

#[flutter_rust_bridge::frb(ignore)]
pub async fn create_matrix_client() -> Result<Client, matrix_sdk::ClientBuildError> {
    Client::builder()
        .homeserver_url("https://matrix.org")
        .build()
        .await
}

#[flutter_rust_bridge::frb(ignore)]
pub async fn get_matrix_login_types() -> Result<String, String> {
    let client = create_matrix_client()
        .await
        .map_err(|error| error.to_string())?;

    let login_types = client
        .matrix_auth()
        .get_login_types()
        .await
        .map_err(|error| error.to_string())?;

    Ok(format!("{login_types:?}"))
}

#[flutter_rust_bridge::frb(ignore)]
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

    Ok(AuthSession {
        user_id: response.user_id.to_string(),
        device_id: response.device_id.to_string(),
        access_token: response.access_token,
        refresh_token: response.refresh_token,
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn should_create_matrix_client() {
        let client = create_matrix_client()
            .await
            .expect("Failed to create Matrix client");

        assert_eq!(
            client.homeserver().as_str(),
            "https://matrix.org/"
        );
    }
}

#[tokio::test]
async fn should_get_matrix_login_types() {
    let login_types = get_matrix_login_types()
        .await
        .expect("Failed to get Matrix login types");

    println!("Supported login types: {login_types}");

    assert!(!login_types.is_empty());
}

#[tokio::test]
async fn should_login_to_matrix() {
    let session = login_matrix(
        "https://matrix.org".to_string(),
        "".to_string(),
        "".to_string(),
    )
    .await
    .expect("Failed to login to Matrix");

    println!("User ID: {}", session.user_id);
    println!("Device ID: {}", session.device_id);

    assert!(!session.user_id.is_empty());
    assert!(!session.device_id.is_empty());
    assert!(!session.access_token.is_empty());
}