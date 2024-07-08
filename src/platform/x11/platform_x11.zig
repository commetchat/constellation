const rl = @import("raylib");
const std = @import("std");
const globals = @import("../../state/globals.zig");

const c = @cImport({
    @cInclude("X11/X.h");
    @cInclude("X11/Xlib.h");
    @cInclude("X11/Xutil.h");
    @cInclude("X11/Xatom.h");
});

pub const Window = struct {
    windowHandle: c.Window,
    platform: *Platform,

    pub fn getPosition(self: Window) rl.Vector2 {
        var attr = std.mem.zeroes(c.XWindowAttributes);
        _ = c.XGetWindowAttributes(self.platform.getXDisplay(), self.windowHandle, &attr);

        return rl.Vector2{ .x = @floatFromInt(attr.x), .y = @floatFromInt(attr.y) };
    }

    pub fn getSize(self: Window) rl.Vector2 {
        var attr = std.mem.zeroes(c.XWindowAttributes);
        _ = c.XGetWindowAttributes(self.platform.getXDisplay(), self.windowHandle, &attr);

        return rl.Vector2{ .x = @floatFromInt(attr.width), .y = @floatFromInt(attr.height) };
    }

    fn getProcId(self: Window) c_ulong {
        const atom_pid = c.XInternAtom(self.platform.getXDisplay(), "_NET_WM_PID", 1);
        var prop_type: c.Atom = std.mem.zeroes(c.Atom);
        var format: c_int = 0;
        var num_items: c_ulong = 0;
        var bytes_after: c_ulong = 0;
        var prop_pid: [*c]u8 = null;

        const result = c.XGetWindowProperty(self.platform.getXDisplay(), self.windowHandle, atom_pid, 0, 1, 0, c.XA_CARDINAL, &prop_type, &format, &num_items, &bytes_after, &prop_pid);
        if (result != c.Success) {
            return 0;
        }

        if (prop_pid == null) {
            return 0;
        }

        const prop_ptr: *c_ulong = @alignCast(@ptrCast(prop_pid));
        return prop_ptr.*;
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
};

pub const Platform = struct {
    display: ?*c.Display,

    pub fn init(self: *Platform) void {
        self.display = null;
    }

    pub fn setAsToolWindow(self: *Platform) void {
        const window = self.findWindowByName(globals.windowName) orelse return;
        const pid = window.getProcId();

        // Stupid hacky way to do this because raylib doesnt allow us to get the actual x11 handle
        if (std.os.linux.getpid() == pid) {
            std.debug.print("Found ourself!\n", .{});

            window.property("_NET_WM_STATE", "_NET_WM_STATE_SKIP_TASKBAR", 1);
            window.property("_NET_WM_STATE", "_NET_WM_STATE_SKIP_PAGER", 1);

            const display = self.getXDisplay() orelse return;

            const windowTypeAtom = c.XInternAtom(display, "_NET_WM_WINDOW_TYPE", 1);
            var windowAtom = c.XInternAtom(display, "_NET_WM_WINDOW_TYPE_TOOLBAR", 1);

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
            const pid = window.getProcId();
            const as_ptr = std.mem.span(name);
            std.debug.print("Window Found: {s} [{d} / {x}]\n", .{ as_ptr, pid, window.windowHandle });

            if (std.mem.eql(u8, as_ptr, window_name)) {
                std.debug.print("FOUND MATCH!\n", .{});
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
};
