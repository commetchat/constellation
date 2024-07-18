const rl = @import("raylib");
const std = @import("std");

pub const cursorA = @embedFile("./textures/cursor_none.dds");
pub const roboto = @embedFile("./font/Roboto-Bold.ttf");

pub var cursorTexture: ?rl.Texture2D = null;
pub var robotoFont: ?rl.Font = null;

pub fn load() void {
    std.debug.print("Loading assets\n", .{});
    const len: i32 = @intCast(cursorA.len);
    std.debug.print("Loading image from {d} bytes\n", .{len});
    const cursorImage = rl.loadImageFromMemory(".dds", cursorA);
    std.debug.print("Loaded image: {d} x {d}\n", .{ cursorImage.width, cursorImage.height });
    cursorTexture = rl.loadTextureFromImage(cursorImage);

    // loadFontFromMemory can accept a null pointer and a length of zero to load default character set
    // raylib-zig however cannot pass these parameters, so I create a slice and set the internal pointer to zero
    // const array = [_]i32{};
    // var slice = array[0..0];
    // const ptrPtr = &slice.ptr;
    // const intptr: *c_ulong = @ptrCast(ptrPtr);
    // intptr.* = 0;

    // robotoFont = rl.loadFontFromMemory(
    //     ".ttf",
    //     roboto,
    //     18,
    //     slice,
    // );
}
