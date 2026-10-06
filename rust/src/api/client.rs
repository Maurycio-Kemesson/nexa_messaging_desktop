use std::{
    sync::{Mutex, OnceLock},
    thread::JoinHandle,
};

use tokio::sync::{broadcast, oneshot};

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

use super::matrix::AuthSession;
use super::rooms::MessageSummary;

static MATRIX_CLIENT: OnceLock<Mutex<Option<Client>>> = OnceLock::new();

fn matrix_client() -> &'static Mutex<Option<Client>> {
    MATRIX_CLIENT.get_or_init(|| Mutex::new(None))
}

static MATRIX_MESSAGE_CHANNEL: OnceLock<broadcast::Sender<MessageSummary>> =
    OnceLock::new();

struct SyncHandle {
    shutdown: oneshot::Sender<()>,
    thread: JoinHandle<()>,
}

static MATRIX_SYNC: OnceLock<Mutex<Option<SyncHandle>>> = OnceLock::new();

fn matrix_sync() -> &'static Mutex<Option<SyncHandle>> {
    MATRIX_SYNC.get_or_init(|| Mutex::new(None))
}

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

async fn build_client(homeserver: &str) -> Result<Client, String> {
    let store_path = matrix_store_path()?;

    Client::builder()
        .homeserver_url(homeserver)
        .sqlite_store(store_path, None)
        .with_encryption_settings(EncryptionSettings {
            auto_enable_cross_signing: true,
            auto_enable_backups: true,
            backup_download_strategy: BackupDownloadStrategy::AfterDecryptionFailure,
        })
        .build()
        .await
        .map_err(|error| error.to_string())
}

/// O login por senha cria um dispositivo novo. O SQLite de outro
/// dispositivo no mesmo diretório faz o SDK recusar o store.
async fn reset_local_matrix_state() -> Result<(), String> {
    let _ = stop_matrix_sync().await;

    {
        let mut stored_client = matrix_client()
            .lock()
            .map_err(|error| error.to_string())?;
        *stored_client = None;
    }

    let store_path = matrix_store_path()?;

    if let Err(error) = std::fs::remove_dir_all(&store_path) {
        if error.kind() != std::io::ErrorKind::NotFound {
            return Err(format!(
                "Não foi possível apagar o store local em {:?}: {error}. Feche o app e apague a pasta.",
                store_path
            ));
        }
    }

    std::fs::create_dir_all(&store_path).map_err(|error| error.to_string())
}

#[flutter_rust_bridge::frb]
pub async fn login_matrix(
    homeserver: String,
    username: String,
    password: String,
) -> Result<AuthSession, String> {
    reset_local_matrix_state().await?;

    let client = build_client(&homeserver).await?;

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
    let client = build_client(&homeserver).await?;

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

#[flutter_rust_bridge::frb]
pub fn start_matrix_sync() -> Result<(), String> {
    let mut sync = matrix_sync()
        .lock()
        .map_err(|error| error.to_string())?;

    if sync
        .as_ref()
        .is_some_and(|handle| !handle.thread.is_finished())
    {
        return Ok(());
    }

    let client = get_authenticated_client()?;

    let (shutdown_sender, shutdown_receiver) = oneshot::channel::<()>();

    let thread = std::thread::spawn(move || {
        let runtime = match tokio::runtime::Builder::new_current_thread()
            .enable_all()
            .build()
        {
            Ok(runtime) => runtime,
            Err(error) => {
                eprintln!("NEXA: erro ao criar runtime do Matrix sync: {error}");
                return;
            }
        };

        runtime.block_on(async move {
            client.add_event_handler(
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

                    let _ = matrix_message_sender().send(message);
                },
            );

            tokio::select! {
                result = client.sync(SyncSettings::default()) => {
                    if let Err(error) = result {
                        eprintln!("NEXA: Matrix sync error: {error}");
                    }
                }
                _ = shutdown_receiver => {}
            }
        });
    });

    *sync = Some(SyncHandle {
        shutdown: shutdown_sender,
        thread,
    });

    Ok(())
}

async fn stop_matrix_sync() -> Result<(), String> {
    let handle = matrix_sync()
        .lock()
        .map_err(|error| error.to_string())?
        .take();

    let Some(handle) = handle else {
        return Ok(());
    };

    let _ = handle.shutdown.send(());

    tokio::task::spawn_blocking(move || handle.thread.join())
        .await
        .map_err(|error| error.to_string())?
        .map_err(|_| "Matrix sync thread panicked".to_string())
}

/// Encerra a sessão no homeserver, para o sync e apaga o store local.
///
/// O estado local é sempre limpo, mesmo que o homeserver esteja inacessível.
/// Nesse caso o erro do servidor é devolvido depois da limpeza.
#[flutter_rust_bridge::frb]
pub async fn logout_matrix() -> Result<(), String> {
    stop_matrix_sync().await?;

    let client = matrix_client()
        .lock()
        .map_err(|error| error.to_string())?
        .take();

    let server_result = match client {
        Some(client) => client
            .logout()
            .await
            .map_err(|error| error.to_string()),
        None => Ok(()),
    };

    let store_path = matrix_store_path()?;

    if let Err(error) = std::fs::remove_dir_all(&store_path) {
        eprintln!("NEXA: não foi possível apagar o store local: {error}");
    }

    server_result
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
pub async fn recover_matrix_encryption(
    recovery_key: String,
) -> Result<(), String> {
    let client = get_authenticated_client()?;

    client
        .encryption()
        .recovery()
        .recover(&recovery_key)
        .await
        .map_err(|error| error.to_string())
}
