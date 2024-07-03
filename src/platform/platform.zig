const std = @import("std");
const builtin = @import("builtin");

pub const platform = switch (builtin.os.tag) {
    .windows => @import("./win32/platform_win32.zig"),
    .linux => @import("./x11/platform_x11.zig"),
    else => @compileError(std.fmt.comptimePrint("Unsupported OS: {}", .{builtin.os.tag})),
};
