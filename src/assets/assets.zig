const rl = @import("raylib");
const std = @import("std");

pub const pointerC = @embedFile("./textures/pointer_c.png");
pub const cursorA = @embedFile("./textures/cursor_none.png");

pub var cursorTexture: ?rl.Texture2D = null;

pub fn load() void {
    const cursorImage = rl.loadImageFromMemory(".png", cursorA);
    std.debug.print("Loaded image: {d} x {d}", .{ cursorImage.width, cursorImage.height });
    cursorTexture = rl.loadTextureFromImage(cursorImage);
}
