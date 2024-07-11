const rl = @import("raylib");
const p = @import("../platform/platform.zig").platform;
const assets = @import("../assets/assets.zig");
const std = @import("std");
const Entity = @import("entity.zig").Entity;
const CursorManager = @import("cursor.zig").CursorManager;
pub const State = struct {
    mutex: std.Thread.Mutex,
    currentWindow: ?p.Window,
    currentDisplay: ?p.Display,
    platform: ?p.Platform,
    cursors: CursorManager,

    pub fn process(self: *State, delta: f32) void {
        if (self.platform == null) return;

        self.processCursors(delta);
        self.processCurrentDesktop();
        self.updateWindowBounds();
    }

    fn updateWindowBounds(self: *State) void {
        const bounds = self.platform.?.getBounds(self);
        if (bounds != null) {
            rl.setWindowPosition(@intFromFloat(bounds.?.x), @intFromFloat(bounds.?.y));
            rl.setWindowSize(@intFromFloat(bounds.?.width), @intFromFloat(bounds.?.height));
        }
    }

    fn processCurrentDesktop(self: *State) void {
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
    }

    fn processCursors(self: *State, delta: f32) void {
        const keys = self.cursors.getKeys() orelse return;
        for (keys) |key| {
            var ptr = self.cursors.getPtr(key) orelse continue;
            ptr.process(delta);
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
            const target_window_desktop = win.getDesktop();
            const current_desktop = self.platform.?.getCurrentDesktop();

            if (target_window_desktop == null) return;
            if (current_desktop == null) return;
            if (target_window_desktop.?.equals(current_desktop.?) == false) return;
        }

        var bounds = self.platform.?.getTargetBounds(self) orelse return;
        const pos = rl.Vector2{ .x = bounds.x, .y = bounds.y };
        const relative_pos = pos.subtract(this_window_pos);

        bounds.x = relative_pos.x;
        bounds.y = relative_pos.y;

        renderWindowOutline(bounds);
        self.renderCursors(bounds);
    }

    fn renderWindowOutline(rect: rl.Rectangle) void {
        rl.drawRectangleLinesEx(
            rect,
            2,
            .{ .a = 255, .r = 255, .g = 0, .b = 255 },
        );
    }

    fn renderCursors(self: *State, rect: rl.Rectangle) void {
        if (assets.cursorTexture == null) return;
        const cursors = self.cursors.getValues() orelse return;

        for (cursors) |value| {
            const pos = rl.Vector2{ .x = rect.x, .y = rect.y };
            const size = rl.Vector2{ .x = rect.width, .y = rect.height };

            const mouse_pos = pos.add(value.pos.multiply(size));

            rl.drawTextureEx(
                assets.cursorTexture.?,
                mouse_pos,
                0,
                1,
                value.color.brightness(0.5),
            );

            if (assets.robotoFont != null) {
                drawTextWithBackground(
                    assets.robotoFont.?,
                    value.displayName,
                    mouse_pos.add(.{ .x = 20, .y = 20 }),
                    18,
                    1,
                    value.color,
                );
            }
        }
    }

    fn drawTextWithBackground(font: rl.Font, text: [:0]const u8, position: rl.Vector2, fontSize: f32, spacing: f32, color: rl.Color) void {
        const size = rl.measureTextEx(font, text, fontSize, spacing);
        const borderPadding = 5;

        rl.drawRectangle(
            @intFromFloat(position.x - borderPadding),
            @intFromFloat(position.y - borderPadding),
            @intFromFloat(size.x + borderPadding * 2),
            @intFromFloat(size.y + borderPadding * 2),
            rl.Color.black.alpha(0.8),
        );

        rl.drawTextEx(
            font,
            text,
            position,
            fontSize,
            spacing,
            color.brightness(0.5),
        );
    }
};
