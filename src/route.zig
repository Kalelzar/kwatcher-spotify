const std = @import("std");
const kwatcher = @import("kwatcher");
const spotify = @import("kwatcher-spotify");

pub fn @"publish:heartbeat amq.direct/heartbeat"(
    user_info: kwatcher.schema.UserInfo,
    client_info: kwatcher.schema.ClientInfo,
    status: spotify.schema.SpotifyStatus,
) kwatcher.schema.Heartbeat.V1(spotify.schema.SpotifyStatus) {
    return .{
        .timestamp = std.time.microTimestamp(),
        .event = "spotify-status",
        .user = user_info.v1(),
        .client = client_info.v1(),
        .properties = status,
    };
}
