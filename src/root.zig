const std = @import("std");
const testing = std.testing;
const main = @import("./main.zig");

export fn _constellation_main() i32 {
    main.main() catch |err| {
        std.debug.print("An error occurred! {any}", .{err});
    };

    return 0;
}

export fn _constellation_add(a: i32, b: i32) i32 {
    return a + b;
}
