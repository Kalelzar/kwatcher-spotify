const std = @import("std");
const kwatcher = @import("kwatcher");

pub const Config = struct {
    spotify: struct {
        id: []const u8,
        secret: []const u8,
        refresh_token: ?[]const u8 = null,
    },
};

pub const FullConfig = kwatcher.meta.MergeStructs(kwatcher.config.BaseConfig, Config);
