const rl = @import("raylib");

pub const Entity = struct {
    pos: rl.Vector2,

    pub fn process(self: *Entity, delta: f32) void {
        _ = self;
        _ = delta;
    }
};
