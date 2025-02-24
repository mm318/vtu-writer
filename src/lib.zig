const std = @import("std");

const Vtu = @import("types.zig");
const VtuImpl = @import("impl.zig");

pub const IndexType = Vtu.IndexType;
pub const CellType = Vtu.CellType;
pub const UnstructuredMesh = Vtu.UnstructuredMesh;

pub fn writeVtu(
    allocator: std.mem.Allocator,
    filename: []const u8,
    mesh: UnstructuredMesh,
    dataSetInfo: []const Vtu.DataSetInfo,
    dataSetData: []const Vtu.DataSetData,
    writeMode: Vtu.WriteMode,
) !void {
    switch (writeMode) {
        .ascii => {
            var writer_impl = VtuImpl.AsciiWriter.init();
            try VtuImpl.writeVtu(
                allocator,
                filename,
                mesh,
                dataSetInfo,
                dataSetData,
                .{ .ascii = &writer_impl },
            );
        },
        .rawbinarycompressed => {
            var writer_impl = VtuImpl.CompressedRawBinaryWriter.init();
            try VtuImpl.writeVtu(
                allocator,
                filename,
                mesh,
                dataSetInfo,
                dataSetData,
                .{ .rawbinarycompressed = &writer_impl },
            );
        },
    }
}
