const std = @import("std");

const Vtu = @import("types.zig");
const VtuImpl = @import("impl.zig");

pub const IndexType = Vtu.IndexType;
pub const CellType = Vtu.CellType;
pub const UnstructuredMesh = Vtu.UnstructuredMesh;
pub const DataSetType = Vtu.DataSetType;
pub const DataSet = Vtu.DataSet;

pub fn writeVtu(
    allocator: std.mem.Allocator,
    filename: []const u8,
    mesh: UnstructuredMesh,
    dataSets: []const DataSet,
    writeMode: Vtu.WriteMode,
) !void {
    switch (writeMode) {
        .ascii => {
            var writer_impl = VtuImpl.AsciiWriter.init();
            try VtuImpl.writeVtu(
                allocator,
                filename,
                mesh,
                dataSets,
                .{ .ascii = &writer_impl },
            );
        },
        .rawbinarycompressed => {
            var writer_impl = VtuImpl.CompressedRawBinaryWriter.init(allocator);
            defer writer_impl.deinit();
            try VtuImpl.writeVtu(
                allocator,
                filename,
                mesh,
                dataSets,
                .{ .rawbinarycompressed = &writer_impl },
            );
        },
    }
}
