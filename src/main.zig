const std = @import("std");
const loop = @import("loop.zig");
const globals = @import("state/globals.zig");
const RndGen = std.rand.DefaultPrng;
const Cursor = @import("state/cursor.zig").Cursor;

const assets = @import("./assets/assets.zig");
pub fn main() anyerror!void {
    _ = try std.Thread.spawn(.{}, loop.loop, .{});

    var rnd = RndGen.init(0);
    while (true) {
        const x = rnd.random().float(f32);
        const y = rnd.random().float(f32);

        globals.state.mutex.lock();

        if (globals.state.platform != null) {
            globals.state.currentWindow = globals.state.platform.?.findWindowByName("*Untitled Document 1 - gedit");
        }

        const key = @mod(rnd.random().int(i32), 5);

        const keyStr = try std.fmt.allocPrintZ(std.heap.page_allocator, "Key_{d}", .{key});
        defer std.heap.page_allocator.free(keyStr);

        const nameStr = try std.fmt.allocPrintZ(std.heap.page_allocator, "User {d}", .{key});
        defer std.heap.page_allocator.free(nameStr);

        if (globals.state.cursors.cursorExists(keyStr)) {
            globals.state.cursors.setTargetPos(keyStr, .{ .x = x, .y = y });
        } else {
            try globals.state.cursors.createCursor(keyStr, nameStr);
            globals.state.cursors.setTargetPos(keyStr, .{ .x = x, .y = y });
            globals.state.cursors.setColor(keyStr, .{
                .a = 255,
                .r = rnd.random().int(u8),
                .g = rnd.random().int(u8),
                .b = rnd.random().int(u8),
            });
        }

        globals.state.mutex.unlock();

        std.time.sleep(2_00_000_000);
    }
}
