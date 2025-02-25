const std = @import("std");

const Vtu = @import("types.zig");
const Utils = @import("utils.zig");

pub const CompressedRawBinaryWriter = struct {
    const appendedAttributes = [_]Vtu.Attribute{.{ "encoding", .{ .str = "raw" } }};

    offset: usize,
    headers: std.ArrayList(std.ArrayList(Vtu.HeaderType)),
    appendedData: std.ArrayList(std.ArrayList(std.ArrayList(Vtu.Byte))),

    pub fn init(allocator: std.mem.Allocator) CompressedRawBinaryWriter {
        return .{
            .offset = 0,
            .headers = std.ArrayList(std.ArrayList(Vtu.HeaderType)).init(allocator),
            .appendedData = std.ArrayList(std.ArrayList(std.ArrayList(Vtu.Byte))).init(allocator),
        };
    }

    pub fn deinit(self: *const CompressedRawBinaryWriter) void {
        for (self.headers.items) |header| {
            header.deinit();
        }
        self.headers.deinit();

        for (self.appendedData.items) |compressedBlocks| {
            for (compressedBlocks.items) |compressedBlock| {
                compressedBlock.deinit();
            }
            compressedBlocks.deinit();
        }
        self.appendedData.deinit();
    }

    pub fn addHeaderAttributes(self: *const CompressedRawBinaryWriter, attributes: *Vtu.Attributes) !void {
        _ = self;
        const headerAttributes = [_]Vtu.Attribute{
            .{ "header_type", .{ .str = Utils.dataTypeString(Vtu.HeaderType) } },
            .{ "compressor", .{ .str = "vtkZLibDataCompressor" } },
        };
        try attributes.appendSlice(&headerAttributes);
    }

    pub fn getAppendedAttributes(self: *const CompressedRawBinaryWriter) []const Vtu.Attribute {
        _ = self;
        return &appendedAttributes;
    }

    pub fn addDataAttributes(self: *const CompressedRawBinaryWriter, attributes: *Vtu.Attributes) !void {
        const dataAttributes = [_]Vtu.Attribute{
            .{ "format", .{ .str = "appended" } },
            .{ "offset", .{ .int = @intCast(self.offset) } },
        };
        try attributes.appendSlice(&dataAttributes);
    }

    fn zlibCompressData(
        dataType: type,
        data: []const dataType,
        header: *std.ArrayList(Vtu.HeaderType),
        targetBlocks: *std.ArrayList(std.ArrayList(Vtu.Byte)),
        customBlockSize: ?usize,
    ) !void {
        _ = data;
        _ = header;
        _ = targetBlocks;
        const blockSize = customBlockSize orelse 32768;
        _ = blockSize;
    }

    pub fn writeData(
        self: *CompressedRawBinaryWriter,
        dataType: type,
        data: []const dataType,
        fileWriter: std.fs.File.Writer,
    ) !void {
        _ = fileWriter;

        var header = std.ArrayList(Vtu.HeaderType).init(self.headers.allocator);
        var compressedBlocks = std.ArrayList(std.ArrayList(Vtu.Byte)).init(self.appendedData.allocator);
        zlibCompressData(dataType, data, &header, &compressedBlocks, null) catch |err| {
            header.deinit();
            compressedBlocks.deinit();
            return err;
        };

        self.offset += @sizeOf(Vtu.HeaderType) * header.items.len;
        for (compressedBlocks.items) |compressedBlock| {
            self.offset += compressedBlock.items.len;
        }

        self.headers.append(header) catch header.deinit();
        self.appendedData.append(compressedBlocks) catch compressedBlocks.deinit();
    }

    pub fn writeAppended(self: *const CompressedRawBinaryWriter, fileWriter: std.fs.File.Writer) !void {
        for (self.headers.items, self.appendedData.items) |header, compressedBlocks| {
            for (header.items) |data| {
                const numberOfBytes = @sizeOf(@TypeOf(data));
                inline for (0..numberOfBytes) |i| {
                    const byte: u8 = @truncate(data >> 8 * i);
                    try fileWriter.writeByte(byte);
                }
            }

            for (compressedBlocks.items) |compressedBlock| {
                for (compressedBlock.items) |byte| {
                    try fileWriter.writeByte(byte);
                }
            }
        }
    }
};
