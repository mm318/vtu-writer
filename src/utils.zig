const std = @import("std");
const builtin = @import("builtin");

const Vtu = @import("types.zig");

pub const StringStringMap = std.StringHashMap([]const u8);

pub fn dataTypeString(dataType: type) []const u8 {
    const result = switch (@typeInfo(dataType)) {
        .@"enum" => |info| return dataTypeString(info.tag_type),
        .int => |info| switch (info.signedness) {
            .signed => "Int",
            .unsigned => "UInt",
        },
        .float => "Float",
        else => @compileError("unsupported data type"),
    };
    return result ++ std.fmt.comptimePrint("{}", .{@bitSizeOf(dataType)});
}

pub fn endianness() []const u8 {
    return switch (builtin.target.cpu.arch.endian()) {
        .little => "LittleEndian",
        .big => "BigEndian",
    };
}

pub fn writeXmlTag(
    writer: *std.io.Writer,
    tagName: []const u8,
    attributes: []const Vtu.Attribute,
    tagEnd: []const u8,
) !void {
    try writer.print("<{s}", .{tagName});

    for (attributes) |entry| {
        switch (entry[1]) {
            Vtu.AttributeValueType.bool => |value| try writer.print(" {s}=\"{}\"", .{ entry[0], value }),
            Vtu.AttributeValueType.int => |value| try writer.print(" {s}=\"{}\"", .{ entry[0], value }),
            Vtu.AttributeValueType.float => |value| try writer.print(" {s}=\"{}\"", .{ entry[0], value }),
            Vtu.AttributeValueType.str => |value| try writer.print(" {s}=\"{s}\"", .{ entry[0], value }),
        }
    }

    try writer.print("{s}\n", .{tagEnd});
}

pub fn openXmlScope(writer: *std.io.Writer, tagName: []const u8, attributes: []const Vtu.Attribute) !void {
    try writeXmlTag(writer, tagName, attributes, ">");
}

pub fn closeXmlScope(writer: *std.io.Writer, tagName: []const u8) !void {
    try writer.print("</{s}>\n", .{tagName});
}

pub fn emptyXmlScope(writer: *std.io.Writer, tagName: []const u8, attributes: []const Vtu.Attribute) !void {
    try writeXmlTag(writer, tagName, attributes, " />");
}

test "ScopedXmlTag_test" {
    const allocator = std.testing.allocator;

    var allocating_writer = std.Io.Writer.Allocating.init(allocator);
    defer allocating_writer.deinit();
    const writer = &allocating_writer.writer;

    {
        openXmlScope(writer, "Test1", &.{
            .{ "attr1", .{ .str = "7" } },
            .{ "attr2", .{ .str = "nice" } },
        }) catch std.log.warn("unable to write to file", .{});
        defer closeXmlScope(writer, "Test1") catch std.log.warn("unable to write to file", .{});

        {
            openXmlScope(writer, "Test2", &.{
                .{ "attr3", .{ .str = "43.32" } },
                .{ "attr4", .{ .str = "[2, 3]" } },
            }) catch std.log.warn("unable to write to file", .{});
            defer closeXmlScope(writer, "Test2") catch std.log.warn("unable to write to file", .{});

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

    std.debug.assert(std.mem.eql(u8, allocating_writer.written(), expected_data));
}
