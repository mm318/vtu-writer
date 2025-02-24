const std = @import("std");
const builtin = @import("builtin");

const vtu_writer = @import("vtu_writer");

test "hello world" {
    std.log.info("hello world!", .{});
}
