#[derive(Debug, Clone)]
pub struct AuthSession {
    pub user_id: String,
    pub device_id: String,
    pub access_token: String,
    pub refresh_token: Option<String>,
}
