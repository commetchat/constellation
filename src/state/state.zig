const rl = @import("raylib");
const p = @import("../platform/platform.zig").platform;

pub const State = struct {
    currentWindow: ?p.Window,

    pub fn process(self: *State, delta: f32) void {
        _ = self;
        _ = delta;
    }

    pub fn render(self: *State, platform: *p.Platform) void {
        rl.beginDrawing();
        defer rl.endDrawing();

        const window_pos = rl.getWindowPosition();

        rl.clearBackground(rl.Color{
            .a = 0,
            .r = 0,
            .g = 0,
            .b = 0,
        });

        if (self.currentWindow != null) {
            const win = self.currentWindow.?;
            var pos = win.getPosition();
            const size = win.getSize();

            rl.setWindowPosition(@intFromFloat(pos.x), @intFromFloat(pos.y));
            rl.setWindowSize(@intFromFloat(size.x), @intFromFloat(size.y));

            pos = pos.subtract(window_pos);

            rl.drawRectangle(@intFromFloat(pos.x), @intFromFloat(pos.y), @intFromFloat(size.x), @intFromFloat(size.y), .{ .a = 50, .r = 255, .g = 0, .b = 0 });
        }

        var mousePos = platform.getMousePosition();
        mousePos = mousePos.subtract(window_pos);

        rl.drawRectangle(
            @intFromFloat(mousePos.x),
            @intFromFloat(mousePos.y),
            50,
            50,
            .{
                .a = 255,
                .r = 0,
                .g = 255,
                .b = 0,
            },
        );
    }
};
