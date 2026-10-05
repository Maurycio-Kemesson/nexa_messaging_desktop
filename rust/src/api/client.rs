use std::sync::{
    atomic::{AtomicBool, Ordering},
    Mutex,
    OnceLock,
};

use tokio::sync::broadcast;

use matrix_sdk::{
    authentication::{
        matrix::MatrixSession,
        SessionTokens,
    },
    config::SyncSettings,
    deserialized_responses::EncryptionInfo,
    encryption::{
        BackupDownloadStrategy,
        EncryptionSettings,
    },
    ruma::{
        events::{
            room::message::{
                MessageType,
                OriginalSyncRoomMessageEvent,
            },
        },
        OwnedDeviceId,
        UserId,
    },
    SessionMeta,
    Client,
};

use super::matrix::{create_matrix_client, AuthSession};
use super::rooms::MessageSummary;

static MATRIX_CLIENT: OnceLock<Mutex<Option<Client>>> = OnceLock::new();

fn matrix_client() -> &'static Mutex<Option<Client>> {
    MATRIX_CLIENT.get_or_init(|| Mutex::new(None))
}

static MATRIX_MESSAGE_CHANNEL: OnceLock<broadcast::Sender<MessageSummary>> =
    OnceLock::new();

static MATRIX_SYNC_STARTED: AtomicBool = AtomicBool::new(false);

#[flutter_rust_bridge::frb(ignore)]
pub fn matrix_message_sender() -> &'static broadcast::Sender<MessageSummary> {
    MATRIX_MESSAGE_CHANNEL.get_or_init(|| {
        let (sender, _) = broadcast::channel(100);
        sender
    })
}

#[flutter_rust_bridge::frb(ignore)]
pub fn subscribe_to_matrix_messages() -> broadcast::Receiver<MessageSummary> {
    matrix_message_sender().subscribe()
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
    let store_path = matrix_store_path()?;

    let client = Client::builder()
        .homeserver_url(&homeserver)
        .sqlite_store(store_path, None)
        .with_encryption_settings(EncryptionSettings {
            auto_enable_cross_signing: true,
            auto_enable_backups: true,
            backup_download_strategy: BackupDownloadStrategy::AfterDecryptionFailure,
        })
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

    println!(
        "NEXA: login concluído user_id={} device_id={}",
        session.user_id,
        session.device_id
    );

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
    println!(
        "NEXA: restaurando sessão user_id={} device_id={}",
        user_id, device_id
    );

    let store_path = matrix_store_path()?;

    println!("NEXA: restaurando SQLite em {:?}", store_path);

    let client = Client::builder()
        .homeserver_url(&homeserver)
        .sqlite_store(store_path, None)
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

    println!(
        "NEXA: chamando restore_session para {} / {}",
        session.meta.user_id,
        session.meta.device_id
    );

    client
        .restore_session(session)
        .await
        .map_err(|error| error.to_string())?;

    println!("NEXA: sessão restaurada com sucesso");

    let mut stored_client = matrix_client()
        .lock()
        .map_err(|error| error.to_string())?;

    *stored_client = Some(client);

    println!("NEXA: cliente Matrix armazenado globalmente");

    Ok(())
}

#[flutter_rust_bridge::frb]
pub fn start_matrix_sync() -> Result<(), String> {
    if MATRIX_SYNC_STARTED.swap(true, Ordering::SeqCst) {
        println!("NEXA: Matrix sync já está iniciado");
        return Ok(());
    }

    let client = match get_authenticated_client() {
        Ok(client) => client,
        Err(error) => {
            MATRIX_SYNC_STARTED.store(false, Ordering::SeqCst);
            return Err(error);
        }
    };

    std::thread::spawn(move || {
        let runtime = match tokio::runtime::Builder::new_current_thread()
            .enable_all()
            .build()
        {
            Ok(runtime) => runtime,
            Err(error) => {
                eprintln!(
                    "NEXA: erro ao criar runtime do Matrix sync: {error}"
                );

                MATRIX_SYNC_STARTED.store(false, Ordering::SeqCst);
                return;
            }
        };

        runtime.block_on(async move {
            println!("NEXA: Matrix sync iniciado");

            let _event_handler = client.add_event_handler(
                move |
                    event: OriginalSyncRoomMessageEvent,
                    room: matrix_sdk::Room,
                    _encryption_info: Option<EncryptionInfo>,
                | async move {
                    let content = match &event.content.msgtype {
                        MessageType::Text(text) => text.body.clone(),
                        _ => return,
                    };

                    let message = MessageSummary {
                        id: event.event_id.to_string(),
                        room_id: room.room_id().to_string(),
                        sender: event.sender.to_string(),
                        content,
                        timestamp: event.origin_server_ts.get().into(),
                    };

                    println!(
                        "NEXA: nova mensagem recebida: {:?}",
                        message
                    );

                    let _ = matrix_message_sender().send(message);
                },
            );

            let result = client
                .sync(SyncSettings::default())
                .await;

            match result {
                Ok(_) => {
                    println!("NEXA: Matrix sync finalizado");
                }

                Err(error) => {
                    eprintln!(
                        "NEXA: Matrix sync error: {error}"
                    );
                }
            }
        });

        MATRIX_SYNC_STARTED.store(false, Ordering::SeqCst);

        println!("NEXA: Matrix sync encerrado");
    });

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

fn matrix_store_path() -> Result<std::path::PathBuf, String> {
    let data_dir = dirs::data_dir()
        .ok_or_else(|| {
            "Unable to determine application data directory".to_string()
        })?;

    let matrix_dir = data_dir
        .join("Nexa Messaging")
        .join("matrix");

    std::fs::create_dir_all(&matrix_dir)
        .map_err(|error| error.to_string())?;

    Ok(matrix_dir)
}

#[flutter_rust_bridge::frb]
pub async fn check_matrix_backup() -> Result<String, String> {
    let client = get_authenticated_client()?;

    let exists = client
        .encryption()
        .backups()
        .fetch_exists_on_server()
        .await
        .map_err(|error| error.to_string())?;

    println!("NEXA: backup existe no servidor? {exists}");

    Ok(format!("backup_exists={exists}"))
}

#[flutter_rust_bridge::frb]
pub async fn recover_matrix_encryption(
    recovery_key: String,
) -> Result<(), String> {
    let client = get_authenticated_client()?;

    println!("NEXA: iniciando recuperação E2EE...");

    client
        .encryption()
        .recovery()
        .recover(&recovery_key)
        .await
        .map_err(|error| error.to_string())?;

    println!("NEXA: recuperação E2EE concluída");

    Ok(())
}