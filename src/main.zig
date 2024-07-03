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

    p.setAsToolWindow();

    defer rl.closeWindow();

    rl.setTargetFPS(60);
    std.debug.print("Got window handle: {x}\n", .{rl.getWindowHandle()});

    var current_pos: rl.Vector2 = p.getMousePosition();

    const window = p.iterateWindows("*Untitled Document 1 - gedit");

    std.debug.print("Foudn window: {x}\n", .{window});
    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        defer rl.endDrawing();

        const other_window_pos = p.getWindowPosition(window);
        const other_window_size = p.getWindowSize(window);

        const mouse = p.getMousePosition();
        const window_relative_mouse_pos = mouse.subtract(other_window_pos);
        current_pos = current_pos.lerp(window_relative_mouse_pos, 10 * rl.getFrameTime());

        const window_pos = rl.getWindowPosition();
        const local_space_mouse_pos = current_pos.subtract(window_pos).add(other_window_pos);

        const local_space_window_pos = other_window_pos.subtract(window_pos);

        rl.clearBackground(rl.Color{
            .a = 0,
            .r = 0,
            .g = 0,
            .b = 0,
        });

        rl.drawRectangle(
            @intFromFloat(local_space_window_pos.x),
            @intFromFloat(local_space_window_pos.y),
            @intFromFloat(other_window_size.x),
            @intFromFloat(other_window_size.y),
            .{ .r = 255, .g = 0, .b = 0, .a = 30 },
        );

        rl.drawRectangleGradientEx(
            .{ .height = 100, .width = 100, .x = local_space_mouse_pos.x, .y = local_space_mouse_pos.y + 50 },
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

        const alloc = std.heap.page_allocator;
        const txt = try std.fmt.allocPrintZ(alloc, "X: {d}, Y: {d}\x00", .{
            mouse.x,
            mouse.y,
        });
        defer alloc.free(txt);

        const window_txt = try std.fmt.allocPrintZ(alloc, "X: {d}, Y: {d}\x00", .{
            other_window_pos.x,
            other_window_pos.y,
        });
        defer alloc.free(window_txt);

        rl.drawText(
            txt,
            @intFromFloat(local_space_mouse_pos.x),
            @intFromFloat(local_space_mouse_pos.y),
            20,
            rl.Color.black,
        );

        rl.drawText(
            window_txt,
            @intFromFloat(local_space_mouse_pos.x),
            @intFromFloat(local_space_mouse_pos.y + 20),
            20,
            rl.Color.black,
        );
    }
}
