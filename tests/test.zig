const std = @import("std");
const builtin = @import("builtin");

const vtu_writer = @import("vtu_writer");

test "hello_world" {
    std.log.info("hello_world 2!", .{});
}
