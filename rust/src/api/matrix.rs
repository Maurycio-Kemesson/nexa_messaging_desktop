use matrix_sdk::Client;

#[flutter_rust_bridge::frb(ignore)]
pub async fn create_matrix_client() -> Result<Client, matrix_sdk::ClientBuildError> {
    Client::builder()
        .homeserver_url("https://matrix.org")
        .build()
        .await
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