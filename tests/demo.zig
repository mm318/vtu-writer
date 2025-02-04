const std = @import("std");
const builtin = @import("builtin");

const vtu_writer = @import("vtu_writer");

pub const std_options: std.Options = .{
    .log_level = switch (builtin.mode) {
        .Debug => .debug,
        else => .info,
    },
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) std.log.warn("memory leaked!", .{});
    }

    try vtu_writer.writeVtu(allocator, "test.vtu", undefined, undefined, undefined, .ascii);
}
