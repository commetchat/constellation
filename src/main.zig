const rl = @import("raylib");
const std = @import("std");
const platform = @import("platform/platform.zig").platform;

pub fn main() anyerror!void {
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

    rl.initWindow(width, height, "raylib-zig [core] example - basic window");

    defer rl.closeWindow();

    rl.setTargetFPS(60);
    std.debug.print("Got window handle: {x}\n", .{rl.getWindowHandle()});

    var x: i32 = 0;

    var currentPos: rl.Vector2 = p.getMousePosition();

    const window = p.iterateWindows("*Untitled Document 1 - gedit");

    std.debug.print("Foudn window: {x}\n", .{window});
    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        defer rl.endDrawing();

        const windowPos = p.getWindowPosition(window);
        const windowSize = p.getWindowSize(window);

        const mouse = p.getMousePosition();

        const windowPosition = rl.getWindowPosition();
        const windowSpaceMousePosition = mouse.subtract(windowPosition);

        const windowSpaceOtherWindowPosition = windowPos.subtract(windowPosition);

        currentPos = currentPos.lerp(windowSpaceMousePosition, 10 * rl.getFrameTime());

        rl.clearBackground(rl.Color{
            .a = 0,
            .r = 0,
            .g = 0,
            .b = 0,
        });

        x = @rem(x + 1, 1000);

        rl.drawRectangle(
            @intFromFloat(windowSpaceOtherWindowPosition.x),
            @intFromFloat(windowSpaceOtherWindowPosition.y),
            @intFromFloat(windowSize.x),
            @intFromFloat(windowSize.y),
            .{ .r = 255, .g = 0, .b = 0, .a = 30 },
        );

        rl.drawRectangleGradientEx(
            .{ .height = 100, .width = 100, .x = currentPos.x, .y = currentPos.y + 20 },
            .{
                .r = 255,
                .g = 0,
                .b = 0,
                .a = 255,
            },
            .{
                .r = 0,
                .g = 0,
                .b = 255,
                .a = 255,
            },
            .{
                .r = 0,
                .g = 255,
                .b = 0,
                .a = 255,
            },
            .{
                .r = 255,
                .g = 255,
                .b = 255,
                .a = 255,
            },
        );

        rl.drawText(
            "Congrats! You created your first window!",
            @intFromFloat(currentPos.x),
            @intFromFloat(currentPos.y),
            20,
            rl.Color.light_gray,
        );
    }
}
