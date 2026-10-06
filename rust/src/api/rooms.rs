use matrix_sdk::{
    room::MessagesOptions,
    ruma::{
        events::{
            AnySyncMessageLikeEvent,
            AnySyncTimelineEvent,
            room::message::{
                MessageType,
                RoomMessageEventContent,
            },
        },
        RoomId,
    },
};

use crate::frb_generated::StreamSink;

use super::client::{
    get_authenticated_client,
    matrix_message_sender,
};

use matrix_sdk::deserialized_responses::TimelineEventKind;

#[derive(Debug, Clone)]
pub struct RoomSummary {
    pub id: String,
    pub name: String,
}

#[derive(Debug, Clone)]
pub struct MessageSummary {
    pub id: String,
    pub room_id: String,
    pub sender: String,
    pub content: String,
    pub timestamp: i64,
}

#[derive(Debug, Clone)]
pub struct MessagesPage {
    pub messages: Vec<MessageSummary>,
    pub end_token: Option<String>,
}

#[flutter_rust_bridge::frb]
pub async fn get_rooms() -> Result<Vec<RoomSummary>, String> {
    let client = get_authenticated_client()?;

    client
        .sync_once(Default::default())
        .await
        .map_err(|error| error.to_string())?;

    let rooms = client.joined_rooms();

    let mut result = Vec::with_capacity(rooms.len());

    for room in rooms {
        let name = room
            .display_name()
            .await
            .map_err(|error| error.to_string())?
            .to_string();

        result.push(RoomSummary {
            id: room.room_id().to_string(),
            name,
        });
    }

    Ok(result)
}

#[flutter_rust_bridge::frb]
pub async fn get_messages(
    room_id: String,
    from_token: Option<String>,
) -> Result<MessagesPage, String> {
    let client = get_authenticated_client()?;

    let room_id = RoomId::parse(&room_id)
        .map_err(|error| error.to_string())?;

    let room = client
        .get_room(&room_id)
        .ok_or_else(|| "Room not found".to_string())?;

    let mut options = MessagesOptions::backward();
    options.limit = 50u32.into();
    options.from = from_token;

    let response = room
        .messages(options)
        .await
        .map_err(|error| error.to_string())?;

    let mut messages = Vec::new();

    for event in response.chunk {
        if matches!(event.kind, TimelineEventKind::UnableToDecrypt { .. }) {
            continue;
        }

        let event = event
            .into_raw()
            .deserialize()
            .map_err(|error| error.to_string())?;

        let AnySyncTimelineEvent::MessageLike(
            AnySyncMessageLikeEvent::RoomMessage(message),
        ) = event
        else {
            continue;
        };

        let Some(message) = message.as_original() else {
            continue;
        };

        let MessageType::Text(text) = &message.content.msgtype else {
            continue;
        };

        let content = text.body.clone();

        messages.push(MessageSummary {
            id: message.event_id.to_string(),
            room_id: room_id.to_string(),
            sender: message.sender.to_string(),
            content,
            timestamp: message.origin_server_ts.get().into(),
        });
    }

    messages.sort_by_key(|message| message.timestamp);

    Ok(MessagesPage {
        messages,
        end_token: response.end,
    })
}

#[flutter_rust_bridge::frb]
pub async fn send_message(
    room_id: String,
    message: String,
) -> Result<(), String> {
    let client = get_authenticated_client()?;

    let room_id = RoomId::parse(&room_id)
        .map_err(|error| error.to_string())?;

    let room = client
        .get_room(&room_id)
        .ok_or_else(|| "Room not found".to_string())?;

    let content = RoomMessageEventContent::text_plain(message);

    room.send(content)
        .await
        .map_err(|error| error.to_string())?;

    Ok(())
}


#[flutter_rust_bridge::frb]
pub async fn subscribe_to_messages(
    sink: StreamSink<MessageSummary>,
) {
    let mut receiver = matrix_message_sender().subscribe();

    loop {
        match receiver.recv().await {
            Ok(message) => {
                if let Err(error) = sink.add(message) {
                    eprintln!(
                        "NEXA: erro ao enviar mensagem para Flutter: {error}"
                    );
                    break;
                }
            }

            Err(
                tokio::sync::broadcast::error::RecvError::Lagged(count)
            ) => {
                eprintln!(
                    "NEXA: broadcast perdeu {count} mensagens"
                );
            }

            Err(
                tokio::sync::broadcast::error::RecvError::Closed
            ) => {
                eprintln!(
                    "NEXA: broadcast encerrado"
                );
                break;
            }
        }
    }
}
