const std = @import("std");
const builtin = @import("builtin");

pub const StringStringMap = std.StringHashMap([]const u8);

pub const AttributeValueType = union(enum) {
    bool: bool,
    int: i32,
    float: f32,
    str: []const u8,
};

pub const Attribute = struct { []const u8, AttributeValueType };

pub fn endianness() []const u8 {
    return switch (builtin.target.cpu.arch.endian()) {
        .little => "LittleEndian",
        .big => "BigEndian",
    };
}

pub fn writeXmlTag(writer: std.fs.File.Writer, tagName: []const u8, attributes: []const Attribute, tagEnd: []const u8) !void {
    try writer.print("<{s}", .{tagName});

    for (attributes) |entry| {
        switch (entry[1]) {
            AttributeValueType.bool => |value| try writer.print(" {s}=\"{}\"", .{ entry[0], value }),
            AttributeValueType.int => |value| try writer.print(" {s}=\"{}\"", .{ entry[0], value }),
            AttributeValueType.float => |value| try writer.print(" {s}=\"{}\"", .{ entry[0], value }),
            AttributeValueType.str => |value| try writer.print(" {s}=\"{s}\"", .{ entry[0], value }),
        }
    }

    try writer.print("{s}\n", .{tagEnd});
}

pub fn openXmlScope(writer: std.fs.File.Writer, tagName: []const u8, attributes: []const Attribute) !void {
    try writeXmlTag(writer, tagName, attributes, ">");
}

pub fn closeXmlScope(writer: std.fs.File.Writer, tagName: []const u8) !void {
    try writer.print("</{s}>\n", .{tagName});
}

pub fn emptyXmlScope(writer: std.fs.File.Writer, tagName: []const u8, attributes: []const Attribute) !void {
    try writeXmlTag(writer, tagName, attributes, "/>");
}
