const std = @import("std");
const testing = std.testing;
const main = @import("./main.zig");
const loop = @import("loop.zig");

const globals = @import("state/globals.zig");
const assets = @import("./assets/assets.zig");

export fn _constellation_start() i32 {
    _ = std.Thread.spawn(.{}, loop.loop, .{}) catch |err| {
        std.debug.print("An error occurred! {any}", .{err});
    };

    return 0;
}

export fn _constellation_set_cursor(x: f32, y: f32) void {
    globals.state.mutex.lock();
    defer globals.state.mutex.unlock();

    globals.state.entity.targetPos = .{
        .x = x,
        .y = y,
    };
}

export fn _constellation_set_window(id: c_ulong) void {
    globals.state.mutex.lock();
    defer globals.state.mutex.unlock();

    if (globals.state.platform == null) {
        return;
    }

    globals.state.currentWindow = globals.state.platform.?.getWindowById(id);
}
