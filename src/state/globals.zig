const State = @import("state.zig").State;

pub var state: State = .{
    .currentWindow = null,
};

pub const windowName: [:0]const u8 = "chat.commet.constellation";
