const std = @import("std");

const Vtu = @import("types.zig");

pub const AsciiWriter = struct {
    pub fn init() AsciiWriter {
        return .{};
    }

    pub fn addHeaderAttributes(self: *const AsciiWriter, attributes: *Vtu.Attributes) !void {
        _ = self;
        _ = attributes;
    }

    pub fn addDataAttributes(self: *const AsciiWriter, attributes: *Vtu.Attributes) !void {
        _ = self;
        const dataAttributes = [_]Vtu.Attribute{
            .{ "format", .{ .str = "ascii" } },
        };
        try attributes.appendSlice(&dataAttributes);
    }

    pub fn writeData(
        self: *const AsciiWriter,
        dataType: type,
        data: []const dataType,
        fileWriter: std.fs.File.Writer,
    ) !void {
        _ = self;
        for (data) |datum| {
            try fileWriter.print("{d} ", .{datum});
        }
        try fileWriter.print("\n", .{});
    }
};
