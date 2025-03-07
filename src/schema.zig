const std = @import("std");
const kwatcher = @import("kwatcher");

pub const SpotifyStatus = struct {
    playing: bool,
    title: ?[]const u8 = null,
    artist: ?[]const u8 = null,
    album: ?[]const u8 = null,
    cover_uri: ?[]const u8 = null,
};

pub const SpotifyHeartbeatProperties = kwatcher.schema.Schema(
    1,
    "spotify",
    SpotifyStatus,
);
