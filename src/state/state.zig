const rl = @import("raylib");
const p = @import("../platform/platform.zig").platform;
const assets = @import("../assets/assets.zig");
const std = @import("std");
const Entity = @import("entity.zig").Entity;
pub const State = struct {
    mutex: std.Thread.Mutex,
    currentWindow: ?p.Window,
    entity: Entity,

    pub fn process(self: *State, delta: f32) void {
        self.entity.process(delta);
    }

    pub fn render(self: *State, platform: *p.Platform) void {
        const window_pos = rl.getWindowPosition();

        rl.clearBackground(rl.Color{
            .a = 50,
            .r = 0,
            .g = 0,
            .b = 0,
        });

        if (self.currentWindow != null) {
            const win = self.currentWindow.?;
            var pos = win.getPosition();
            const size = win.getSize();

            // rl.setWindowPosition(@intFromFloat(pos.x), @intFromFloat(pos.y));
            // rl.setWindowSize(@intFromFloat(size.x), @intFromFloat(size.y));

            pos = pos.subtract(window_pos);

            rl.drawRectangle(
                @intFromFloat(pos.x),
                @intFromFloat(pos.y),
                @intFromFloat(size.x),
                @intFromFloat(size.y),
                .{ .a = 10, .r = 0, .g = 0, .b = 0 },
            );
        }

        var mousePos = platform.getMousePosition();
        mousePos = mousePos.subtract(window_pos);

        rl.drawRectangle(
            @intFromFloat(self.entity.pos.x),
            @intFromFloat(self.entity.pos.y),
            50,
            50,
            .{
                .r = 150,
                .g = 255,
                .b = 255,
                .a = 255,
            },
        );

        if (assets.cursorTexture != null) {
            rl.drawTextureEx(
                assets.cursorTexture.?,
                mousePos,
                0,
                0.5,
                .{ .a = 255, .b = 255, .g = 150, .r = 150 },
            );
        } else {
            rl.drawRectangle(
                @intFromFloat(mousePos.x),
                @intFromFloat(mousePos.y),
                50,
                50,
                .{ .a = 255, .b = 255, .g = 100, .r = 100 },
            );
        }
    }
};