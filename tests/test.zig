const std = @import("std");

pub const hexahedras3D_test = @import("hexahedras3D_test.zig");
pub const icosahedron3D_test = @import("icosahedron3D_test.zig");
pub const pyramids3D_test = @import("pyramids3D_test.zig");
pub const square2D_test = @import("square2D_test.zig");
pub const utilities_test = @import("utilities_test.zig");

test {
    std.testing.refAllDecls(@This());
}
