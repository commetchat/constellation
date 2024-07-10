const rl = @import("raylib");
const std = @import("std");
const platform = @import("platform/platform.zig").platform;
const assets = @import("./assets/assets.zig");

const globals = @import("state/globals.zig");

pub fn loop() anyerror!void {
    std.debug.print("Initializing main loop\n", .{});
    var p = std.mem.zeroes(platform.Platform);
    p.init();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    globals.state.mutex.lock();
    globals.state.platform = p;
    globals.state.cursors.init(allocator);
    globals.state.mutex.unlock();

    rl.setConfigFlags(rl.ConfigFlags{
        .window_transparent = true,
        .window_mouse_passthrough = true,
        .window_undecorated = true,
        .window_topmost = true,
        .borderless_windowed_mode = true,
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

    p.setAsToolWindow();

    std.debug.print("Set as tool window\n", .{});

    rl.setTargetFPS(120);
    std.debug.print("Got window handle: {x}\n", .{rl.getWindowHandle()});

    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        defer rl.endDrawing();

        globals.state.mutex.lock();
        defer globals.state.mutex.unlock();

        globals.state.process(rl.getFrameTime());
        globals.state.render();
    }
}
