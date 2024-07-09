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
        const this_window_pos = rl.getWindowPosition();

        rl.clearBackground(rl.Color{
            .a = 0,
            .r = 0,
            .g = 0,
            .b = 0,
        });

        if (self.currentWindow != null) {
            const win = self.currentWindow.?;
            const target_window_pos = win.getPosition();
            const size = win.getSize();

            const relative_window_pos = target_window_pos.subtract(this_window_pos);

            // rl.setWindowPosition(@intFromFloat(pos.x), @intFromFloat(pos.y));
            // rl.setWindowSize(@intFromFloat(size.x), @intFromFloat(size.y));

            const mouse_pos = relative_window_pos.add(self.entity.pos.multiply(size));

            if (assets.cursorTexture != null) {
                rl.drawTextureEx(
                    assets.cursorTexture.?,
                    mouse_pos,
                    0,
                    0.5,
                    .{ .a = 255, .b = 255, .g = 150, .r = 150 },
                );
            }

            rl.drawRectangle(
                @intFromFloat(relative_window_pos.x),
                @intFromFloat(relative_window_pos.y),
                @intFromFloat(size.x),
                @intFromFloat(size.y),
                .{ .a = 50, .r = 255, .g = 0, .b = 0 },
            );
        }

        var mousePos = platform.getMousePosition();
        mousePos = mousePos.subtract(this_window_pos);
    }
};
