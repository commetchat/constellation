const rl = @import("raylib");
const std = @import("std");

pub const cursorA = @embedFile("./textures/cursor_none.dds");

pub var cursorTexture: ?rl.Texture2D = null;

pub fn load() void {
    const len: i32 = @intCast(cursorA.len);
    std.debug.print("Loading image from {d} bytes\n", .{len});
    const cursorImage = rl.loadImageFromMemory(".dds", cursorA);
    std.debug.print("Loaded image: {d} x {d}", .{ cursorImage.width, cursorImage.height });
    cursorTexture = rl.loadTextureFromImage(cursorImage);
}
