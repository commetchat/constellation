const rl = @import("raylib");
const std = @import("std");
const globals = @import("../../state/globals.zig");
const State = @import("../../state/state.zig").State;

const win = @cImport({
    @cInclude("Windows.h");
    @cInclude("dwmapi.h");
});

pub const Desktop = struct {
    index: u32,

    pub fn equals(self: Desktop, other: Desktop) bool {
        return self.index == other.index;
    }
};

pub const Display = struct {
    handle: win.HMONITOR,
    rect: win.RECT,
};

pub const Window = struct {
    handle: win.HWND,

    pub fn getPosition(self: Window) rl.Vector2 {
        var rect = std.mem.zeroes(win.RECT);
        _ = win.DwmGetWindowAttribute(self.handle, win.DWMWA_EXTENDED_FRAME_BOUNDS, &rect, @sizeOf(win.RECT));

        // var rect = std.mem.zeroes(win.RECT);
        // _ = win.GetWindowRect(self.handle, &rect);

        return rl.Vector2{
            .x = @floatFromInt(rect.left),
            .y = @floatFromInt(rect.top),
        };
    }

    pub fn getSize(self: Window) rl.Vector2 {
        // var rect = std.mem.zeroes(win.RECT);
        // _ = win.GetWindowRect(self.handle, &rect);
        var rect = std.mem.zeroes(win.RECT);
        _ = win.DwmGetWindowAttribute(self.handle, win.DWMWA_EXTENDED_FRAME_BOUNDS, &rect, @sizeOf(win.RECT));

        return rl.Vector2{
            .x = @floatFromInt(rect.right - rect.left),
            .y = @floatFromInt(rect.bottom - rect.top),
        };
    }

    pub fn isVisible(self: Window) bool {
        var vis = win.IsWindowVisible(self.handle) == 1;

        var cloaked: u32 = 0;
        const result = win.DwmGetWindowAttribute(self.handle, win.DWMWA_CLOAKED, &cloaked, 4);
        if (result == win.S_OK) {
            vis = vis and cloaked == 0;
        }

        return vis;
    }
};

const WS_EX_TOPMOST = 0x00000008;
const WS_EX_TRANSPARENT = 0x00000020;
const WS_EX_LAYERED = 0x00080000;
const WS_EX_TOOLWINDOW = 0x00000080;
const HWND_TOPMOST: win.HWND = std.zig.c_translation.cast(win.HWND, @as(c_int, -1));

pub const Platform = struct {
    thisWindow: ?Window,

    pub fn init(self: *Platform) void {
        _ = self;
    }

    pub fn setAsToolWindow(self: *Platform) void {
        const ptr = @intFromPtr(rl.getWindowHandle());
        const hwnd = @as(win.HWND, ptr);

        self.thisWindow = Window{ .handle = hwnd };
        const style = WS_EX_TOPMOST | WS_EX_TRANSPARENT | WS_EX_LAYERED | WS_EX_TOOLWINDOW;
        _ = win.SetWindowLongPtrA(self.thisWindow.?.handle, win.GWL_EXSTYLE, style);
    }

    // Gets bounds required for overlay window size
    pub fn getBounds(self: *Platform, state: *State) ?rl.Rectangle {
        _ = self;

        if (state.currentWindow != null) {
            const pos = state.currentWindow.?.getPosition();
            const size = state.currentWindow.?.getSize();

            return rl.Rectangle{
                .x = pos.x,
                .y = pos.y,
                .width = size.x,
                .height = size.y,
            };
        }

        if (state.currentDisplay != null) {
            const rect = state.currentDisplay.?.rect;
            return rl.Rectangle{
                .x = @floatFromInt(rect.left),
                .y = @floatFromInt(rect.top),
                .width = @floatFromInt(rect.right - rect.left),
                .height = @floatFromInt(rect.bottom - rect.top),
            };
        }

        return null;
    }

    // gets bounds required for the window we want to draw over
    pub fn getTargetBounds(self: *Platform, state: *State) ?rl.Rectangle {
        _ = self;
        if (state.currentWindow != null) {
            const pos = state.currentWindow.?.getPosition();
            const size = state.currentWindow.?.getSize();

            return rl.Rectangle{
                .x = pos.x,
                .y = pos.y,
                .width = size.x,
                .height = size.y,
            };
        }

        if (state.currentDisplay != null) {
            const rect = state.currentDisplay.?.rect;
            return rl.Rectangle{
                .x = @floatFromInt(rect.left),
                .y = @floatFromInt(rect.top),
                .width = @floatFromInt(rect.right - rect.left),
                .height = @floatFromInt(rect.bottom - rect.top),
            };
        }

        return null;
    }

    const monitorEnumInfo = struct {
        index: c_int,
        display: ?Display,
    };

    pub fn getDisplay(self: *Platform, id: []const u8) ?Display {
        _ = self;

        const index = std.fmt.parseInt(c_int, id, 10) catch {
            return null;
        };

        var info = monitorEnumInfo{
            .index = index,
            .display = null,
        };

        const ptr: usize = @intFromPtr(&info);
        _ = win.EnumDisplayMonitors(null, null, enumMonitorsCallback, @intCast(ptr));

        return info.display;
    }

    fn enumMonitorsCallback(monitor: win.HMONITOR, hdc: win.HDC, lprcMonitor: win.LPRECT, dwData: win.LPARAM) callconv(.C) win.WINBOOL {
        _ = hdc;
        const s: usize = @intCast(dwData);
        var out: *monitorEnumInfo = @ptrFromInt(s);

        std.debug.print("Enumerating monitors! {any}\n", .{lprcMonitor.*.left});
        out.index -= 1;
        if (out.index < 0) {
            std.debug.print("Found correct monitor!\n", .{});
            out.display = Display{
                .handle = monitor,
                .rect = lprcMonitor.*,
            };
            return 0;
        }

        std.debug.print("This isnt the monitor we are looking for...\n", .{});

        return 1;
    }

    pub fn findWindowByName(self: *Platform, windowName: []const u8) ?Window {
        std.debug.print("Finding window: {s}\n", .{windowName});
        _ = self;

        _ = win.EnumWindows(enumWindowsCallback, 0);

        const result = win.FindWindowExA(0, 0, 0, @ptrCast(windowName));
        if (result != 0) {
            return Window{ .handle = result };
        }

        return null;
    }

    fn enumWindowsCallback(window: win.HWND, param: win.LPARAM) callconv(.C) win.WINBOOL {
        _ = param;

        var procId: c_ulong = 0;
        _ = win.GetWindowThreadProcessId(window, &procId);

        if (procId == std.os.windows.kernel32.GetCurrentProcessId()) {
            return 1;
        }

        const buf = std.heap.page_allocator.alloc(u8, 128) catch {
            return 1;
        };

        defer std.heap.page_allocator.free(buf);

        const len: usize = @intCast(win.GetWindowTextA(window, @ptrCast(buf), 128));

        if (len == 0) {
            return 1;
        }

        std.debug.print("Found window: '{s}'\n", .{buf[0..len]});

        return 1;
    }

    pub fn getWindowById(self: *Platform, id: []const u8) ?Window {
        _ = self;

        const handle = std.fmt.parseInt(c_ulong, id, 10) catch {
            return null;
        };

        if (win.IsWindow(handle) == 1) {
            return Window{ .handle = handle };
        }
        return null;
    }

    pub fn ensureOverlayVisible(self: *Platform) void {
        _ = self;
    }
};
