const rl = @import("raylib");
const std = @import("std");
const platform = @import("platform/platform.zig").platform;
const assets = @import("./assets/assets.zig");

const globals = @import("state/globals.zig");

pub fn loop() anyerror!void {
    std.debug.print("Initializing main loop\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    globals.state.mutex.lock();
    var p = std.mem.zeroes(platform.Platform);
    p.init();

    globals.state.platform = p;
    globals.state.cursors.init(allocator);
    globals.state.mutex.unlock();

    rl.setConfigFlags(rl.ConfigFlags{
        .window_transparent = true,
        .window_mouse_passthrough = true,
        .window_undecorated = true,
        .window_topmost = true,
        .borderless_windowed_mode = false,
        .window_maximized = false,
        .window_always_run = true,
        .window_unfocused = true,
    });

    std.debug.print("Set config flags\n", .{});

    const width = rl.getScreenHeight();
    const height = rl.getScreenHeight();
    rl.initWindow(width, height, globals.windowName);
    defer rl.closeWindow();

    std.debug.print("Init window\n", .{});

    assets.load();

    std.debug.print("Loaded assets\n", .{});

    std.debug.print("Set as tool window\n", .{});

    std.debug.print("Set target fps!\n", .{});

    globals.state.mutex.lock();
    std.debug.print("Got lock\n", .{});
    globals.state.platform.?.setAsToolWindow();
    globals.state.mutex.unlock();

    std.debug.print("Unlocked\n", .{});

    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        defer rl.endDrawing();

        globals.state.mutex.lock();
        defer globals.state.mutex.unlock();

        globals.state.process(rl.getFrameTime());
        globals.state.render();
    }
}
