use super::client::get_authenticated_client;

#[derive(Debug, Clone)]
pub struct RoomSummary {
    pub id: String,
    pub name: String,
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