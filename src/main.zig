const std = @import("std");
const loop = @import("loop.zig");
const globals = @import("state/globals.zig");
const RndGen = std.rand.DefaultPrng;

pub fn main() anyerror!void {
    _ = try std.Thread.spawn(.{}, loop.loop, .{});

    var rnd = RndGen.init(0);
    while (true) {
        const x = rnd.random().float(f32);
        const y = rnd.random().float(f32);

        globals.state.mutex.lock();
        globals.state.entity.targetPos = .{
            .x = x,
            .y = y,
        };
        globals.state.mutex.unlock();

        std.time.sleep(2_000_000_000);
    }
}
