const rl = @import("raylib");
const p = @import("../platform/platform.zig").platform;
const assets = @import("../assets/assets.zig");
const std = @import("std");
const Entity = @import("entity.zig").Entity;
const CursorManager = @import("cursor.zig").CursorManager;
pub const State = struct {
    mutex: std.Thread.Mutex,
    currentWindow: ?p.Window,
    platform: ?p.Platform,
    cursors: CursorManager,

    pub fn process(self: *State, delta: f32) void {
        if (self.platform == null) return;

        const desktop = self.platform.?.getCurrentDesktop();

        if (self.platform.?.thisWindow == null) {
            std.debug.print("Could not find reference to our own window!\n", .{});
        }

        if (desktop != null and self.platform.?.thisWindow != null) {
            var overlayDesktop = self.platform.?.thisWindow.?.getDesktop();
            if (overlayDesktop != null and !overlayDesktop.?.equals(desktop.?)) {
                self.platform.?.moveWindowToDesktop(self.platform.?.thisWindow.?, desktop.?);
            }
        }

        const keys = self.cursors.getKeys() orelse return;
        for (keys) |key| {
            var ptr = self.cursors.getPtr(key) orelse continue;
            ptr.process(delta);
        }

        const bounds = self.platform.?.getBounds(self);
        if (bounds != null) {
            rl.setWindowPosition(@intFromFloat(bounds.?.x), @intFromFloat(bounds.?.y));
            rl.setWindowSize(@intFromFloat(bounds.?.width), @intFromFloat(bounds.?.height));
        }
    }

    pub fn render(self: *State) void {
        if (self.platform == null) return;
        const this_window_pos = rl.getWindowPosition();

        rl.clearBackground(rl.Color{
            .a = 0,
            .r = 0,
            .g = 0,
            .b = 0,
        });

        if (self.currentWindow != null) {
            const win = self.currentWindow.?;
            const desktop = win.getDesktop();
            const currentDesktop = self.platform.?.getCurrentDesktop();
            const target_window_pos = win.getPosition();
            const size = win.getSize();

            const relative_window_pos = target_window_pos.subtract(this_window_pos);

            if (desktop != null and currentDesktop != null and desktop.?.equals(currentDesktop.?)) {
                renderWindowOutline(relative_window_pos, size);
                self.renderCursors(relative_window_pos, size);
            }
        }

        var mousePos = self.platform.?.getMousePosition();
        mousePos = mousePos.subtract(this_window_pos);
    }

    fn renderWindowOutline(relative_window_pos: rl.Vector2, window_size: rl.Vector2) void {
        rl.drawRectangleLinesEx(
            .{
                .x = relative_window_pos.x,
                .y = relative_window_pos.y,
                .width = window_size.x,
                .height = window_size.y,
            },
            2,
            .{ .a = 255, .r = 255, .g = 0, .b = 255 },
        );
    }

    fn renderCursors(self: *State, relative_window_pos: rl.Vector2, window_size: rl.Vector2) void {
        if (assets.cursorTexture == null) return;
        const cursors = self.cursors.getValues() orelse return;

        for (cursors) |value| {
            const mouse_pos = relative_window_pos.add(value.pos.multiply(window_size));

            rl.drawTextureEx(
                assets.cursorTexture.?,
                mouse_pos,
                0,
                0.5,
                value.color,
            );

            rl.drawText(
                value.displayName,
                @intFromFloat(mouse_pos.x + 20),
                @intFromFloat(mouse_pos.y + 20),
                24,
                value.color,
            );
        }
    }
};
