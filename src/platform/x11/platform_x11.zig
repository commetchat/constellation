const rl = @import("raylib");
const std = @import("std");
const globals = @import("../../state/globals.zig");
const State = @import("../../state/state.zig").State;

const c = @cImport({
    @cInclude("X11/X.h");
    @cInclude("X11/Xlib.h");
    @cInclude("X11/Xutil.h");
    @cInclude("X11/Xatom.h");
    @cInclude("X11/extensions/Xrandr.h");
});

pub const Desktop = struct {
    index: c_ulong,

    pub fn equals(self: Desktop, other: Desktop) bool {
        return self.index == other.index;
    }
};

pub const Display = struct {
    x: c_int,
    y: c_int,
    width: c_ulong,
    height: c_ulong,
};

pub const Window = struct {
    windowHandle: c.Window,
    platform: *Platform,

    pub fn getPosition(self: Window) rl.Vector2 {
        const display = self.platform.getXDisplay() orelse return rl.Vector2{ .x = 0, .y = 0 };

        const root = c.XRootWindow(display, 0);
        var x: i32 = 0;
        var y: i32 = 0;
        var child: c.Window = 0;

        _ = c.XTranslateCoordinates(display, self.windowHandle, root, 0, 0, &x, &y, &child);

        return rl.Vector2{
            .x = @floatFromInt(x),
            .y = @floatFromInt(y),
        };
    }

    pub fn getSize(self: Window) rl.Vector2 {
        var attr = std.mem.zeroes(c.XWindowAttributes);
        _ = c.XGetWindowAttributes(self.platform.getXDisplay(), self.windowHandle, &attr);

        return rl.Vector2{ .x = @floatFromInt(attr.width), .y = @floatFromInt(attr.height) };
    }

    fn getProcId(self: Window) c_ulong {
        const result = self.platform.getCardinalProperty(self.windowHandle, "_NET_WM_PID") orelse return 0;
        return result;
    }

    pub fn getDesktop(self: Window) ?Desktop {
        const index = self.platform.getCardinalProperty(self.windowHandle, "_NET_WM_DESKTOP") orelse return null;
        return Desktop{ .index = @intCast(index) };
    }

    fn property(
        self: Window,
        atom_type: [*c]const u8,
        atom_property: [*c]const u8,
        set: c_long,
    ) void {
        const display = self.platform.getXDisplay();
        const t = c.XInternAtom(display, atom_type, 1);
        const p = c.XInternAtom(display, atom_property, 1);
        if (t == c.None) {
            std.debug.print("no such atom\n", .{});
        }

        if (p == c.None) {
            std.debug.print("no such atom\n", .{});
        }

        var event = std.mem.zeroes(c.XClientMessageEvent);
        event.type = c.ClientMessage;
        event.window = self.windowHandle;
        event.message_type = t;
        event.send_event = c.True;
        event.format = 32;
        event.data.l[0] = set;
        event.data.l[1] = @intCast(p);
        event.data.l[2] = 0;
        event.data.l[3] = 0;
        event.data.l[4] = 0;

        const send_event: [*c]c.union__XEvent = @ptrCast(&event);

        const result = c.XSendEvent(display, self.windowHandle, c.True, c.SubstructureRedirectMask | c.SubstructureNotifyMask, send_event);
        std.debug.print("Send message result: {d}\n", .{result});
    }

    pub fn isVisible(self: Window) bool {
        const desktop = self.getDesktop() orelse return false;
        const currentDesktop = self.platform.getCurrentDesktop() orelse return false;

        return desktop.equals(currentDesktop);
    }
};

pub const Platform = struct {
    display: ?*c.Display,
    thisWindow: ?Window,

    pub fn init(self: *Platform) void {
        self.display = null;
        _ = c.XSetErrorHandler(onError);
    }

    pub fn onError(display: ?*c.Display, err: [*c]c.XErrorEvent) callconv(.C) c_int {
        _ = display;

        std.debug.print("X Error: {d}\n", .{err.*.error_code});

        return 0;
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
                .height = size.y,
                .width = size.x,
            };
        }

        if (state.currentDisplay != null) {
            return rl.Rectangle{
                .x = @floatFromInt(state.currentDisplay.?.x),
                .y = @floatFromInt(state.currentDisplay.?.y),
                .width = @floatFromInt(state.currentDisplay.?.width),
                .height = @floatFromInt(state.currentDisplay.?.height),
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
            return rl.Rectangle{
                .x = @floatFromInt(state.currentDisplay.?.x),
                .y = @floatFromInt(state.currentDisplay.?.y),
                .width = @floatFromInt(state.currentDisplay.?.width),
                .height = @floatFromInt(state.currentDisplay.?.height),
            };
        }

        return null;
    }

    fn getCardinalProperty(self: *Platform, window: c.Window, prop: [*c]const u8) ?c_ulong {
        const display = self.getXDisplay();

        const atom_pid = c.XInternAtom(display, prop, 1);
        var prop_type: c.Atom = std.mem.zeroes(c.Atom);
        var format: c_int = 0;
        var num_items: c_ulong = 0;
        var bytes_after: c_ulong = 0;
        var result: [*c]u8 = null;

        const success = c.XGetWindowProperty(
            display,
            window,
            atom_pid,
            0,
            1,
            0,
            c.XA_CARDINAL,
            &prop_type,
            &format,
            &num_items,
            &bytes_after,
            &result,
        );

        if (success != c.Success) {
            std.debug.print("Get desktop failed!\n", .{});
            return null;
        }

        if (result == null) {
            std.debug.print("Result was null! failed!\n", .{});
            return null;
        }

        const prop_ptr: *c_ulong = @alignCast(@ptrCast(result));
        const returnVal = prop_ptr.*;

        _ = c.XFree(result);

        return returnVal;
    }

    pub fn getCurrentDesktop(self: *Platform) ?Desktop {
        const display = self.getXDisplay();
        const root = c.XDefaultRootWindow(display);

        const desktop = self.getCardinalProperty(root, "_NET_CURRENT_DESKTOP") orelse return null;

        return .{ .index = @intCast(desktop) };
    }

    pub fn getDisplay(self: *Platform, id: []const u8) ?Display {
        const id_atom = std.fmt.parseInt(c_ulong, id, 10) catch {
            return null;
        };

        const display = self.getXDisplay() orelse return null;
        const root = c.XDefaultRootWindow(display);

        var n_monitors: c_int = 0;
        const monitors = c.XRRGetMonitors(display, root, 0, &n_monitors);
        defer _ = c.XFree(monitors);

        for (0..@intCast(n_monitors)) |index| {
            const m = monitors[index];
            if (m.name == id_atom) {
                std.debug.print("Found Correct monitor: {any}\n", .{m.name});
                return Display{
                    .x = m.x,
                    .y = m.y,
                    .width = @intCast(m.width),
                    .height = @intCast(m.height),
                };
            }
        }

        return null;
    }

    pub fn setAsToolWindow(self: *Platform) void {
        const window = self.findWindowByName(globals.windowName) orelse {
            std.debug.print("Failed to get window for ourself (couldn't find window)\n", .{});
            return;
        };
        const pid = window.getProcId();

        // Stupid hacky way to do this because raylib doesnt allow us to get the actual x11 handle
        if (std.os.linux.getpid() != pid) {
            std.debug.print("Failed to get window for ourself\n", .{});
            return;
        }

        self.thisWindow = window;
        std.debug.print("Found ourself! {any}\n", .{window});

        window.property("_NET_WM_STATE", "_NET_WM_STATE_SKIP_TASKBAR", 1);
        window.property("_NET_WM_STATE", "_NET_WM_STATE_SKIP_PAGER", 1);

        const display = self.getXDisplay() orelse return;

        const windowTypeAtom = c.XInternAtom(display, "_NET_WM_WINDOW_TYPE", 1);
        var windowAtom = c.XInternAtom(display, "_NET_WM_WINDOW_TYPE_DOCK", 1);

        _ = c.XChangeProperty(
            display,
            window.windowHandle,
            windowTypeAtom,
            c.XA_ATOM,
            32,
            c.PropModeReplace,
            @ptrCast(&windowAtom),
            1,
        );
    }

    pub fn moveWindowToDesktop(self: *Platform, window: Window, desktop: Desktop) void {
        const display = self.getXDisplay();
        var event = std.mem.zeroes(c.XClientMessageEvent);
        const t = c.XInternAtom(display, "_NET_WM_DESKTOP", 1);
        event.type = c.ClientMessage;
        event.window = window.windowHandle;
        event.message_type = t;
        event.send_event = c.True;
        event.format = 32;
        event.data.l[0] = @bitCast(desktop.index);
        event.data.l[1] = 0;
        event.data.l[2] = 0;
        event.data.l[3] = 0;
        event.data.l[4] = 0;

        const send_event: [*c]c.union__XEvent = @ptrCast(&event);

        _ = c.XSendEvent(display, window.windowHandle, c.True, c.SubstructureRedirectMask | c.SubstructureNotifyMask, send_event);
    }

    fn getXDisplay(self: *Platform) ?*c.Display {
        if (self.display == null) {
            self.display = c.XOpenDisplay(null);
        }

        return self.display;
    }

    pub fn getMousePosition(self: *Platform) rl.Vector2 {
        const display = self.getXDisplay();

        if (display == null) {
            return rl.Vector2{ .x = 0, .y = 0 };
        }

        const num_screens = c.XScreenCount(display);

        if (num_screens > 0) {
            const root = c.XRootWindow(display, 0);
            var x: i32 = 0;
            var y: i32 = 0;
            var win_x: i32 = 0;
            var win_y: i32 = 0;
            var mask: u32 = 0;
            var w = std.mem.zeroes(c.Window);

            _ = c.XQueryPointer(display, root, &w, &w, &x, &y, &win_x, &win_y, &mask);

            return rl.Vector2{ .x = @floatFromInt(x), .y = @floatFromInt(y) };
        }

        return rl.Vector2{ .x = 0, .y = 0 };
    }

    pub fn findWindowByName(self: *Platform, windowName: []const u8) ?Window {
        const display = self.getXDisplay();

        const root = c.XDefaultRootWindow(display);
        const win = Window{ .windowHandle = root, .platform = self };

        return iterateChildren(@ptrCast(display), win, windowName);
    }

    pub fn getWindowById(self: *Platform, id: []const u8) ?Window {
        const handle = std.fmt.parseInt(c_ulong, id, 10) catch {
            return null;
        };
        return Window{ .windowHandle = handle, .platform = self };
    }

    fn iterateChildren(
        display: *c.struct__XDisplay,
        window: Window,
        window_name: []const u8,
    ) ?Window {
        var name: [*c]u8 = null;
        var children: [*c]c_ulong = null;
        var parent: c.Window = std.mem.zeroes(c.Window);
        var root: c.Window = std.mem.zeroes(c.Window);
        var attr: c.XWindowAttributes = std.mem.zeroes(c.XWindowAttributes);

        var num_children: c_uint = 0;

        const name_result = c.XFetchName(display, window.windowHandle, &name);
        defer _ = c.XFree(@ptrCast(name));

        _ = c.XGetWindowAttributes(display, window.windowHandle, &attr);

        if (name_result > 0) {
            const as_ptr = std.mem.span(name);

            if (std.mem.eql(u8, as_ptr, window_name)) {
                return window;
            }
        }

        const result = c.XQueryTree(display, window.windowHandle, &root, &parent, &children, &num_children);
        defer _ = c.XFree(@ptrCast(children));

        if (result == 0) {
            return null;
        }

        for (0..num_children) |i| {
            const child = children[i];
            const child_window = Window{ .windowHandle = child, .platform = window.platform };
            const found = iterateChildren(display, child_window, window_name);
            if (found != null) {
                return found.?;
            }
        }

        return null;
    }

    pub fn ensureOverlayVisible(self: *Platform) void {
        if (self.thisWindow == null) return;

        const currentDesktop = self.getCurrentDesktop() orelse return;
        const overlayCurrentDesktop = self.thisWindow.?.getDesktop() orelse return;

        if (overlayCurrentDesktop.equals(currentDesktop) == false) {
            self.moveWindowToDesktop(self.thisWindow.?, currentDesktop);
        }
    }
};
