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
