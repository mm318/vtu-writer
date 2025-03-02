const std = @import("std");

const Utils = @import("../src/utils.zig");

test "ScopedXmlTag_test" {
    const allocator = std.testing.allocator;

    var written_data = std.ArrayList(u8).init(allocator);
    defer written_data.deinit();
    const writer = written_data.writer().any();

    {
        Utils.openXmlScope(writer, "Test1", &.{
            .{ "attr1", .{ .str = "7" } },
            .{ "attr2", .{ .str = "nice" } },
        }) catch std.log.warn("unable to write to file", .{});
        defer Utils.closeXmlScope(writer, "Test1") catch std.log.warn("unable to write to file", .{});

        {
            Utils.openXmlScope(writer, "Test2", &.{
                .{ "attr3", .{ .str = "43.32" } },
                .{ "attr4", .{ .str = "[2, 3]" } },
            }) catch std.log.warn("unable to write to file", .{});
            defer Utils.closeXmlScope(writer, "Test2") catch std.log.warn("unable to write to file", .{});

            try writer.print("dadatata\n", .{});
        }
    }

    const expected_data =
        \\<Test1 attr1="7" attr2="nice">
        \\<Test2 attr3="43.32" attr4="[2, 3]">
        \\dadatata
        \\</Test2>
        \\</Test1>
        \\
    ;

    // std.log.err("{s}\nlen={}", .{written_data.items, written_data.items.len});
    // std.log.err("{s}\nlen={}", .{expected_data, expected_data.len});

    std.debug.assert(std.mem.eql(u8, written_data.items, expected_data));
}
