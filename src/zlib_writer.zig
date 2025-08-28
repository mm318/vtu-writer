const std = @import("std");

const Vtu = @import("types.zig");
const Utils = @import("utils.zig");
const z = @cImport({
    @cInclude("zlib.h");
});

pub const CompressedRawBinaryWriter = struct {
    const appendedAttributes = [_]Vtu.Attribute{.{ "encoding", .{ .str = "raw" } }};

    allocator: std.mem.Allocator,
    offset: usize,
    headers: std.ArrayList(std.ArrayList(Vtu.HeaderType)),
    appendedData: std.ArrayList(std.ArrayList(std.ArrayList(Vtu.Byte))),

    pub fn init(allocator: std.mem.Allocator) CompressedRawBinaryWriter {
        return .{
            .allocator = allocator,
            .offset = 0,
            .headers = std.ArrayList(std.ArrayList(Vtu.HeaderType)).initCapacity(allocator, 2) catch unreachable,
            .appendedData = std.ArrayList(std.ArrayList(std.ArrayList(Vtu.Byte))).initCapacity(allocator, 0) catch unreachable,
        };
    }

    pub fn deinit(self: *CompressedRawBinaryWriter) void {
        for (self.headers.items) |*header| {
            header.deinit(self.allocator);
        }
        self.headers.deinit(self.allocator);

        for (self.appendedData.items) |*compressedBlocks| {
            for (compressedBlocks.items) |*compressedBlock| {
                compressedBlock.deinit(self.allocator);
            }
            compressedBlocks.deinit(self.allocator);
        }
        self.appendedData.deinit(self.allocator);
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
        self: *CompressedRawBinaryWriter,
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

        try header.appendNTimes(self.allocator, 0, 3);

        if (data.len <= 0) {
            return;
        }

        const compressedBuffersize = z.compressBound(blockSize);
        const buffer = try self.allocator.alloc(u8, compressedBuffersize);
        defer self.allocator.free(buffer);

        const Closure = struct {
            allocator: std.mem.Allocator,
            buffer: []Vtu.Byte,
            currentByte: [*c]const Vtu.Byte,
            header: *std.ArrayList(Vtu.HeaderType),
            targetBlocks: *std.ArrayList(std.ArrayList(Vtu.Byte)),

            pub fn compressBlock(closure: *@This(), numberOfBytesInBlock: IntType) !void {
                var compressedLength: IntType = closure.buffer.len;
                const errorCode = z.compress(closure.buffer.ptr, &compressedLength, closure.currentByte, numberOfBytesInBlock);
                if (errorCode != z.Z_OK) {
                    std.log.err("Error in zlib compression (code {}).", .{errorCode});
                    return error.CompressionError;
                }

                try closure.header.append(closure.allocator, compressedLength);

                var newBlock = try std.ArrayList(Vtu.Byte).initCapacity(closure.allocator, compressedLength);
                try newBlock.appendSlice(closure.allocator, closure.buffer[0..compressedLength]);
                try closure.targetBlocks.append(closure.allocator, newBlock);

                closure.currentByte += numberOfBytesInBlock;
            }
        };
        var closure = Closure{
            .allocator = self.allocator,
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
        fileWriter: *std.io.Writer,
    ) !void {
        _ = fileWriter;

        var header = try std.ArrayList(Vtu.HeaderType).initCapacity(self.allocator, 0);
        var compressedBlocks = try std.ArrayList(std.ArrayList(Vtu.Byte)).initCapacity(self.allocator, 0);
        zlibCompressData(self, dataType, data, &header, &compressedBlocks, null) catch |err| {
            header.deinit(self.allocator);
            compressedBlocks.deinit(self.allocator);
            return err;
        };

        self.offset += @sizeOf(Vtu.HeaderType) * header.items.len;
        for (compressedBlocks.items) |compressedBlock| {
            self.offset += compressedBlock.items.len;
        }

        self.headers.append(self.allocator, header) catch header.deinit(self.allocator);
        self.appendedData.append(self.allocator, compressedBlocks) catch compressedBlocks.deinit(self.allocator);
    }

    pub fn writeAppended(self: *const CompressedRawBinaryWriter, fileWriter: *std.io.Writer) !void {
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
