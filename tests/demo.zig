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

    std.log.info("Running VTU AsciiWriter...", .{});
    try vtu_writer.writeVtu(allocator, "test_ascii.vtu", undefined, undefined, undefined, .ascii);
    std.log.info("Finished running VTU AsciiWriter\n", .{});

    std.log.info("Running VTU CompressedRawBinaryWriter...", .{});
    try vtu_writer.writeVtu(allocator, "test_binary.vtu", undefined, undefined, undefined, .rawbinarycompressed);
    std.log.info("Finished running VTU CompressedRawBinaryWriter\n", .{});
}
