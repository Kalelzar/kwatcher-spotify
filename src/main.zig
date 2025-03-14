const std = @import("std");
const kwatcher = @import("kwatcher");
const kwatcher_spotify = @import("kwatcher-spotify");
const spotify = @import("spotify");

const routes = @import("route.zig");

const SingletonDependencies = struct {
    client: ?*spotify.Client = null,

    pub fn spotifyClient(self: *SingletonDependencies, allocator: std.mem.Allocator, config: kwatcher_spotify.config.Config) !*spotify.Client {
        if (self.client) |c| {
            return c;
        } else {
            const client = try spotify.Client.init(allocator, config.spotify.id, config.spotify.secret, config.spotify.refresh_token);

            try client.auth.auth(allocator, .{
                .scopes = "user-read-playback-state",
            });

            const newConfig = kwatcher_spotify.config.Config{
                .spotify = .{
                    .id = client.id,
                    .secret = client.secret,
                    .refresh_token = (client.auth.info orelse unreachable).refresh_token,
                },
            };
            try kwatcher.config.findConfigFileToUpdate(newConfig, allocator, "spotify");

            self.client = client;
            return self.client.?;
        }
    }

    pub fn deinit(self: *SingletonDependencies, allocator: std.mem.Allocator) void {
        if (self.client) |c| {
            c.deinit(allocator);
            allocator.destroy(c);
        }
    }

    pub fn status(client: *spotify.Client, persistant: std.mem.Allocator, arena: *kwatcher.mem.InternalArena) !kwatcher_spotify.schema.SpotifyStatus {
        const allocator = arena.allocator();
        const playback = try client.getPlaybackState(persistant);
        if (std.time.timestamp() - client.auth.last_refresh < 30) {
            const newConfig = kwatcher_spotify.config.Config{
                .spotify = .{
                    .id = client.id,
                    .secret = client.secret,
                    .refresh_token = (client.auth.info orelse unreachable).refresh_token,
                },
            };
            try kwatcher.config.findConfigFileToUpdate(newConfig, allocator, "spotify");
        }
        if (playback) |p| {
            defer p.deinit();
            return .{
                .playing = p.value.is_playing,
                .title = try allocator.dupe(u8, p.value.item.track.name),
                .album = try allocator.dupe(u8, p.value.item.track.album.name),
                .artist = try allocator.dupe(u8, p.value.item.track.artists[0].name),
                .cover_uri = try allocator.dupe(u8, p.value.item.track.album.images[0].url),
            };
        } else {
            return .{
                .playing = false,
            };
        }
    }
};

const ScopedDependencies = struct {};

const EventProvider = struct {
    pub fn heartbeat(timer: kwatcher.server.Timer) !bool {
        return try timer.ready("heartbeat");
    }

    pub fn disabled() bool {
        return false;
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    var singleton = SingletonDependencies{};
    defer singleton.deinit(allocator);

    var server = try kwatcher.server.Server(
        "spotify",
        "0.1.0",
        SingletonDependencies,
        ScopedDependencies,
        kwatcher_spotify.config.Config,
        routes,
        EventProvider,
    ).init(allocator, &singleton);
    defer server.deinit();

    try server.start();
}
