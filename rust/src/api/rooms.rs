use matrix_sdk::{
    ruma::{
        RoomId,
        events::{
            AnySyncMessageLikeEvent,
            AnySyncTimelineEvent,
            room::message::MessageType,
        },
    },
    room::MessagesOptions,
};
use super::client::get_authenticated_client;

#[derive(Debug, Clone)]
pub struct RoomSummary {
    pub id: String,
    pub name: String,
}

#[derive(Debug, Clone)]
pub struct MessageSummary {
    pub id: String,
    pub sender: String,
    pub content: String,
    pub timestamp: i64,
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
pub async fn get_messages(room_id: String) -> Result<Vec<MessageSummary>, String> {
    let client = get_authenticated_client()?;

    let room_id = RoomId::parse(&room_id)
        .map_err(|error| error.to_string())?;

    let room = client
        .get_room(&room_id)
        .ok_or_else(|| "Room not found".to_string())?;

    let mut options = MessagesOptions::backward();

    options.limit = 50u32.into();

    let response = room
        .messages(options)
        .await
        .map_err(|error| error.to_string())?;

    let mut messages = Vec::new();

    for event in response.chunk {
        let event = event
            .raw()
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

        let content = match &message.content.msgtype {
            MessageType::Text(text) => text.body.clone(),
            _ => continue,
        };

        messages.push(MessageSummary {
            id: message.event_id.to_string(),
            sender: message.sender.to_string(),
            content,
            timestamp: message.origin_server_ts.get().into(),
        });
    }

    messages.sort_by_key(|message| message.timestamp);

    Ok(messages)
}