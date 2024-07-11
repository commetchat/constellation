const State = @import("state.zig").State;
const Cursor = @import("cursor.zig").Cursor;
const std = @import("std");

pub var state: State = .{
    .mutex = .{},
    .currentWindow = null,
    .currentDisplay = null,
    .platform = null,
    .cursors = .{
        ._allocator = null,
        ._cursors = null,
    },
};

pub const windowName: [:0]const u8 = "chat.commet.constellation";
