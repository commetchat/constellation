const State = @import("state.zig").State;

pub var state: State = .{
    .mutex = .{},
    .currentWindow = null,
    .entity = .{
        .pos = .{ .x = 0, .y = 0 },
        .targetPos = .{ .x = 0, .y = 0 },
    },
};

pub const windowName: [:0]const u8 = "chat.commet.constellation";
