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

export fn _constellation_set_window(id: c_ulong) void {
    globals.state.mutex.lock();
    defer globals.state.mutex.unlock();

    if (globals.state.platform == null) {
        return;
    }

    globals.state.currentWindow = globals.state.platform.?.getWindowById(id);
}

export fn _constellation_create_cursor(key: [*:0]const u8, display_name: [*:0]const u8) void {
    globals.state.mutex.lock();
    defer globals.state.mutex.unlock();

    const key_slice = std.mem.span(key);
    const display_name_slice = std.mem.span(display_name);

    globals.state.cursors.createCursor(key_slice, display_name_slice) catch {
        std.debug.print("Failed to create cursor\n", .{});
    };
}

export fn _constellation_set_cursor_position(key: [*:0]const u8, x: f32, y: f32) void {
    globals.state.mutex.lock();
    defer globals.state.mutex.unlock();

    const key_slice = std.mem.span(key);

    globals.state.cursors.setTargetPos(key_slice, .{ .x = x, .y = y });
}

export fn _constellation_set_cursor_color(key: [*:0]const u8, r: u8, g: u8, b: u8, a: u8) void {
    globals.state.mutex.lock();
    defer globals.state.mutex.unlock();

    const key_slice = std.mem.span(key);

    globals.state.cursors.setColor(key_slice, .{
        .r = r,
        .g = g,
        .b = b,
        .a = a,
    });
}
