const rl = @import("raylib");
const p = @import("../platform/platform.zig").platform;
const assets = @import("../assets/assets.zig");
const std = @import("std");
const Entity = @import("entity.zig").Entity;
pub const State = struct {
    mutex: std.Thread.Mutex,
    currentWindow: ?p.Window,
    platform: ?p.Platform,
    entity: Entity,

    pub fn process(self: *State, delta: f32) void {
        self.entity.process(delta);

        const desktop = self.platform.?.getCurrentDesktop();

        if (desktop != null and self.platform.?.thisWindow != null) {
            var overlayDesktop = self.platform.?.thisWindow.?.getDesktop();
            if (overlayDesktop != null and !overlayDesktop.?.equals(desktop.?)) {
                self.platform.?.moveWindowToDesktop(self.platform.?.thisWindow.?, desktop.?);
            }
        }
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
            const desktop = win.getDesktop();
            const currentDesktop = self.platform.?.getCurrentDesktop();
            const target_window_pos = win.getPosition();
            const size = win.getSize();

            const relative_window_pos = target_window_pos.subtract(this_window_pos);

            const mouse_pos = relative_window_pos.add(self.entity.pos.multiply(size));

            rl.drawRectangleLinesEx(
                .{
                    .x = relative_window_pos.x,
                    .y = relative_window_pos.y,
                    .width = size.x,
                    .height = size.y,
                },
                2,
                .{ .a = 255, .r = 255, .g = 0, .b = 255 },
            );

            if (desktop != null and currentDesktop != null and desktop.?.equals(currentDesktop.?)) {
                if (assets.cursorTexture != null) {
                    rl.drawTextureEx(
                        assets.cursorTexture.?,
                        mouse_pos,
                        0,
                        0.5,
                        .{ .a = 255, .b = 255, .g = 150, .r = 150 },
                    );
                }
            }
        }

        var mousePos = platform.getMousePosition();
        mousePos = mousePos.subtract(this_window_pos);
    }
};
