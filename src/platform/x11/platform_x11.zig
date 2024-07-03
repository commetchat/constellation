const rl = @import("raylib");
const std = @import("std");

const c = @cImport({
    @cInclude("X11/X.h");
    @cInclude("X11/Xlib.h");
    @cInclude("X11/Xutil.h");
    @cInclude("X11/Xatom.h");
});

pub const Platform = struct {
    display: ?*c.Display,

    pub fn init(self: *Platform) void {
        self.display = null;
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

    pub fn iterateWindows(self: *Platform, windowName: []const u8) *anyopaque {
        const display = self.getXDisplay();
        const atomPID = c.XInternAtom(display, "_NET_WM_PID", 1);

        const root = c.XDefaultRootWindow(display);
        return @ptrFromInt(iterateChildren(@ptrCast(display), root, atomPID, windowName));
    }

    pub fn getWindowPosition(self: *Platform, window: *anyopaque) rl.Vector2 {
        var attr = std.mem.zeroes(c.XWindowAttributes);
        _ = c.XGetWindowAttributes(self.getXDisplay(), @intFromPtr(window), &attr);

        return rl.Vector2{ .x = @floatFromInt(attr.x), .y = @floatFromInt(attr.y) };
    }

    pub fn getWindowSize(self: *Platform, window: *anyopaque) rl.Vector2 {
        var attr = std.mem.zeroes(c.XWindowAttributes);
        _ = c.XGetWindowAttributes(self.getXDisplay(), @intFromPtr(window), &attr);

        return rl.Vector2{ .x = @floatFromInt(attr.width), .y = @floatFromInt(attr.height) };
    }

    fn iterateChildren(
        display: *c.struct__XDisplay,
        window: c.Window,
        atom: c_ulong,
        windowName: []const u8,
    ) c.Window {
        var name: [*c]u8 = null;
        var children: [*c]c_ulong = null;
        var parent: c.Window = std.mem.zeroes(c.Window);
        var root: c.Window = std.mem.zeroes(c.Window);
        var attr: c.XWindowAttributes = std.mem.zeroes(c.XWindowAttributes);

        var childCount: c_uint = 0;

        const numBytes = c.XFetchName(display, window, &name);
        defer _ = c.XFree(@ptrCast(name));

        _ = c.XGetWindowAttributes(display, window, &attr);

        if (numBytes > 0) {
            const pid = getWindowProcId(display, window, atom);
            const as_ptr = std.mem.span(name);
            std.debug.print("Window Found: {s} [{d} / {x}]\n", .{ as_ptr, pid, window });

            if (std.mem.eql(u8, as_ptr, windowName)) {
                std.debug.print("FOUND MATCH!\n", .{});
                return window;
            }

            // Stupid hacky way to do this because raylib doesnt allow us to get the actual x11 handle
            if (std.os.linux.getpid() == pid) {
                std.debug.print("Found ourself!\n", .{});

                property(display, window, "_NET_WM_STATE", "_NET_WM_STATE_SKIP_TASKBAR", 1);
                property(display, window, "_NET_WM_STATE", "_NET_WM_STATE_SKIP_PAGER", 1);
            }
        }

        const result = c.XQueryTree(display, window, &root, &parent, &children, &childCount);
        defer _ = c.XFree(@ptrCast(children));

        if (result == 0) {
            return 0;
        }

        for (0..childCount) |i| {
            const child = children[i];
            const found = iterateChildren(display, child, atom, windowName);
            if (found != 0) {
                return found;
            }
        }

        return 0;
    }

    fn getWindowProcId(
        display: *c.struct__XDisplay,
        window: c.Window,
        atom: c_ulong,
    ) c_ulong {
        var propertyType: c.Atom = std.mem.zeroes(c.Atom);
        var format: c_int = 0;
        var nItems: c_ulong = 0;
        var bytesAfter: c_ulong = 0;
        var propPid: [*c]u8 = null;

        const result = c.XGetWindowProperty(display, window, atom, 0, 1, 0, c.XA_CARDINAL, &propertyType, &format, &nItems, &bytesAfter, &propPid);
        if (result != c.Success) {
            return 0;
        }

        if (propPid == null) {
            return 0;
        }

        const propPtr: *c_ulong = @alignCast(@ptrCast(propPid));
        return propPtr.*;
    }

    fn property(
        display: *c.struct__XDisplay,
        window: c.Window,
        atomType: [*c]const u8,
        atomProperty: [*c]const u8,
        set: c_long,
    ) void {
        const t = c.XInternAtom(display, atomType, 1);
        const p = c.XInternAtom(display, atomProperty, 1);
        if (t == c.None) {
            std.debug.print("no such atom\n", .{});
        }

        if (p == c.None) {
            std.debug.print("no such atom\n", .{});
        }

        var event = std.mem.zeroes(c.XClientMessageEvent);
        event.type = c.ClientMessage;
        event.window = window;
        event.message_type = t;
        event.send_event = c.True;
        event.format = 32;
        event.data.l[0] = set;
        event.data.l[1] = @intCast(p);
        event.data.l[2] = 0;
        event.data.l[3] = 0;
        event.data.l[4] = 0;

        const sendEvent: [*c]c.union__XEvent = @ptrCast(&event);

        const result = c.XSendEvent(display, window, c.True, c.SubstructureRedirectMask | c.SubstructureNotifyMask, sendEvent);
        std.debug.print("Send message result: {d}\n", .{result});
    }
};
