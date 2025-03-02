const std = @import("std");

const Vtu = @import("types.zig");
const Utils = @import("utils.zig");
const z = @cImport({
    @cInclude("zlib.h");
});

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
        allocator: std.mem.Allocator,
        dataType: type,
        data: []const dataType,
        header: *std.ArrayList(Vtu.HeaderType),
        targetBlocks: *std.ArrayList(std.ArrayList(Vtu.Byte)),
        customBlockSize: ?usize,
    ) !void {
        const IntType = z.uLong;
        const blockSize = customBlockSize orelse 32768;
        if (data.len > std.math.maxInt(IntType) or blockSize > std.math.maxInt(IntType)) {
            std.log.err("Size too large for uLong zlib type.", .{});
            return error.DataTooLarge;
        }

        try header.appendNTimes(0, 3);

        if (data.len <= 0) {
            return;
        }

        const compressedBuffersize = z.compressBound(blockSize);
        const buffer = try allocator.alloc(u8, compressedBuffersize);
        defer allocator.free(buffer);

        const Closure = struct {
            const Self = @This();
            buffer: []Vtu.Byte,
            currentByte: [*c]const Vtu.Byte,
            header: *std.ArrayList(Vtu.HeaderType),
            targetBlocks: *std.ArrayList(std.ArrayList(Vtu.Byte)),

            pub fn compressBlock(self: *Self, numberOfBytesInBlock: IntType) !void {
                var compressedLength: IntType = self.buffer.len;
                const errorCode = z.compress(self.buffer.ptr, &compressedLength, self.currentByte, numberOfBytesInBlock);
                if (errorCode != z.Z_OK) {
                    std.log.err("Error in zlib compression (code {}).", .{errorCode});
                    return error.CompressionError;
                }

                try self.header.append(compressedLength);

                var newBlock = std.ArrayList(Vtu.Byte).init(self.targetBlocks.allocator);
                try newBlock.appendSlice(self.buffer[0..compressedLength]);
                try self.targetBlocks.append(newBlock);

                self.currentByte += numberOfBytesInBlock;
            }
        };
        var closure = Closure{
            .buffer = buffer,
            .currentByte = @ptrCast(data.ptr), // TODO: this assumes little-endian
            .header = header,
            .targetBlocks = targetBlocks,
        };

        const numberOfBytes: IntType = data.len * @sizeOf(dataType);
        const numberOfBlocks: IntType = (numberOfBytes - 1) / blockSize + 1;
        for (0..numberOfBlocks - 1) |_| {
            try closure.compressBlock(blockSize);
        }
        const remainder: IntType = numberOfBytes - (numberOfBlocks - 1) * blockSize;
        try closure.compressBlock(remainder);

        header.items[0] = header.items.len - 3;
        header.items[1] = blockSize;
        header.items[2] = remainder;
    }

    pub fn writeData(
        self: *CompressedRawBinaryWriter,
        dataType: type,
        data: []const dataType,
        fileWriter: std.io.AnyWriter,
    ) !void {
        _ = fileWriter;

        var header = std.ArrayList(Vtu.HeaderType).init(self.headers.allocator);
        var compressedBlocks = std.ArrayList(std.ArrayList(Vtu.Byte)).init(self.appendedData.allocator);
        zlibCompressData(self.appendedData.allocator, dataType, data, &header, &compressedBlocks, null) catch |err| {
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

    pub fn writeAppended(self: *const CompressedRawBinaryWriter, fileWriter: std.io.AnyWriter) !void {
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
        try fileWriter.writeByte('\n');
    }
};
