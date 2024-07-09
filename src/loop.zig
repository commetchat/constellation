const rl = @import("raylib");
const std = @import("std");
const platform = @import("platform/platform.zig").platform;
const assets = @import("./assets/assets.zig");

const globals = @import("state/globals.zig");

pub fn loop() anyerror!void {
    var p = std.mem.zeroes(platform.Platform);
    p.init();

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

    const width = rl.getScreenHeight();
    const height = rl.getScreenHeight();
    rl.initWindow(width, height, globals.windowName);

    assets.load();

    p.setAsToolWindow();

    defer rl.closeWindow();

    rl.setTargetFPS(120);
    std.debug.print("Got window handle: {x}\n", .{rl.getWindowHandle()});

    globals.state.mutex.lock();
    globals.state.currentWindow = p.findWindowByName("*Untitled Document 1 - gedit");
    globals.state.mutex.unlock();

    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        defer rl.endDrawing();

        globals.state.mutex.lock();

        globals.state.process(rl.getFrameTime());
        globals.state.render(&p);

        globals.state.mutex.unlock();
    }
}
