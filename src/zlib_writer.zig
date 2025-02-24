const std = @import("std");

const Vtu = @import("types.zig");
const Utils = @import("utils.zig");

pub const CompressedRawBinaryWriter = struct {
    offset: usize,

    pub fn init() CompressedRawBinaryWriter {
        return .{ .offset = 0 };
    }

    pub fn addHeaderAttributes(self: *const CompressedRawBinaryWriter, attributes: *Vtu.Attributes) !void {
        _ = self;
        const headerAttributes = [_]Vtu.Attribute{
            .{ "header_type", .{ .str = Utils.dataTypeString(Vtu.HeaderType) } },
            .{ "compressor", .{ .str = "vtkZLibDataCompressor" } },
        };
        try attributes.appendSlice(&headerAttributes);
    }

    pub fn addDataAttributes(self: *const CompressedRawBinaryWriter, attributes: *Vtu.Attributes) !void {
        const dataAttributes = [_]Vtu.Attribute{
            .{ "format", .{ .str = "appended" } },
            .{ "offset", .{ .int = @intCast(self.offset) } },
        };
        try attributes.appendSlice(&dataAttributes);
    }

    pub fn writeData(
        self: *const CompressedRawBinaryWriter,
        dataType: type,
        data: []const dataType,
        fileWriter: std.fs.File.Writer,
    ) !void {
        _ = self;
        _ = data;
        _ = fileWriter;
    }
};
