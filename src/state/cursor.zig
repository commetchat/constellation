const rl = @import("raylib");
const std = @import("std");

pub const Cursor = struct {
    pos: rl.Vector2,
    targetPos: rl.Vector2,
    color: rl.Color,
    displayName: [:0]const u8,
    id: [:0]const u8,

    pub fn process(self: *Cursor, delta: f32) void {
        self.pos = self.pos.lerp(self.targetPos, 20 * delta);
    }
};

pub const CursorManager = struct {
    _cursors: ?std.StringArrayHashMap(
        Cursor,
    ),

    _allocator: ?std.mem.Allocator,

    pub fn init(self: *CursorManager, allocator: std.mem.Allocator) void {
        self._allocator = allocator;
        self._cursors = std.StringArrayHashMap(Cursor).init(allocator);
    }

    pub fn createCursor(self: *CursorManager, id: []const u8, displayName: []const u8) !void {
        if (self._allocator == null) return;
        if (self._cursors == null) return;

        const key = try self._allocator.?.dupeZ(u8, id);
        const name = try self._allocator.?.dupeZ(u8, displayName);

        const value = Cursor{
            .color = .{ .a = 255, .r = 255, .g = 255, .b = 255 },
            .displayName = name,
            .id = key,
            .pos = .{ .x = 0, .y = 0 },
            .targetPos = .{ .x = 0, .y = 0 },
        };

        try self._cursors.?.put(key, value);
    }

    pub fn removeCursor(self: *CursorManager, id: []const u8) void {
        if (self._allocator == null) return;
        if (self.cursorExists(id) == false) return;

        const value = self._cursors.?.fetchOrderedRemove(id) orelse return;
        self._allocator.?.free(value.value.displayName);
        self._allocator.?.free(value.key);
    }

    pub fn cursorExists(self: *CursorManager, id: []const u8) bool {
        if (self._cursors == null) return false;
        return self._cursors.?.contains(id);
    }

    pub fn setColor(self: *CursorManager, id: []const u8, color: rl.Color) void {
        if (self.cursorExists(id) == false) return;

        var ptr = self._cursors.?.getPtr(id) orelse return;
        ptr.color = color;
    }

    pub fn setTargetPos(self: *CursorManager, id: []const u8, pos: rl.Vector2) void {
        if (self.cursorExists(id) == false) return;

        var ptr = self._cursors.?.getPtr(id) orelse return;
        ptr.targetPos = pos;
    }

    pub fn getPtr(self: *CursorManager, id: []const u8) ?*Cursor {
        if (self._cursors == null) return null;
        return self._cursors.?.getPtr(id);
    }

    pub fn getKeys(self: *CursorManager) ?[][]const u8 {
        if (self._cursors == null) return null;

        return self._cursors.?.keys();
    }

    pub fn getValues(self: *CursorManager) ?[]Cursor {
        if (self._cursors == null) return null;

        return self._cursors.?.values();
    }
};
