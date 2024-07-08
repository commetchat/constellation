const rl = @import("raylib");

pub const Entity = struct {
    pos: rl.Vector2,
    targetPos: rl.Vector2,

    pub fn process(self: *Entity, delta: f32) void {
        self.pos = self.pos.lerp(self.targetPos, 10 * delta);
    }
};
