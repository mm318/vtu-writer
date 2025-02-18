const std = @import("std");

const Vtu = @import("types.zig");
const VtuImpl = @import("impl.zig");

pub fn writeVtu(
    allocator: std.mem.Allocator,
    filename: []const u8,
    mesh: Vtu.UnstructuredMesh,
    dataSetInfo: []const Vtu.DataSetInfo,
    dataSetData: []const Vtu.DataSetData,
    writeMode: Vtu.WriteMode,
) !void {
    switch (writeMode) {
        .ascii => {
            var vtuWriter = VtuImpl.AsciiWriter.init();
            try VtuImpl.writeVtu(
                allocator,
                filename,
                mesh,
                dataSetInfo,
                dataSetData,
                &vtuWriter.writer,
            );
        },
        .rawbinarycompressed => {
            var vtuWriter = VtuImpl.CompressedRawBinaryWriter.init();
            try VtuImpl.writeVtu(
                allocator,
                filename,
                mesh,
                dataSetInfo,
                dataSetData,
                &vtuWriter.writer,
            );
        },
    }
}
