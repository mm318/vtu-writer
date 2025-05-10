const std = @import("std");
const builtin = @import("builtin");

const VtuWriter = @import("vtu_writer");

pub const std_options: std.Options = .{
    .log_level = switch (builtin.mode) {
        .Debug => .debug,
        else => .info,
    },
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) std.log.warn("memory leaked!", .{});
    }

    // Create data for 3x2 quad mesh: (x, y, z) coordinates of mesh vertices
    const points = [_]f64{
        0.0, 0.0, 0.5, 0.0, 0.3, 0.5, 0.0, 0.7, 0.5, 0.0, 1.0, 0.5, // 0,  1,  2,  3
        0.5, 0.0, 0.5, 0.5, 0.3, 0.5, 0.5, 0.7, 0.5, 0.5, 1.0, 0.5, // 4,  5,  6,  7
        1.0, 0.0, 0.5, 1.0, 0.3, 0.5, 1.0, 0.7, 0.5, 1.0, 1.0, 0.5, // 8,  9, 10, 11
    };

    // Vertex indices of all cells
    const connectivity = [_]VtuWriter.IndexType{
        0, 4, 5, 1, // 0
        1, 5, 6, 2, // 1
        2, 6, 7, 3, // 2
        4, 8, 9, 5, // 3
        5, 9, 10, 6, // 4
        6, 10, 11, 7, // 5
    };

    // Separate cells in connectivity array
    const offsets = [_]VtuWriter.IndexType{ 4, 8, 12, 16, 20, 24 };

    // Cell types of each cell, see [1]
    const types = [_]VtuWriter.CellType{ .VTK_QUAD, .VTK_QUAD, .VTK_QUAD, .VTK_QUAD, .VTK_QUAD, .VTK_QUAD };

    const mesh = VtuWriter.UnstructuredMesh{
        .points = &points,
        .connectivity = &connectivity,
        .offsets = &offsets,
        .types = &types,
    };

    // Create some data associated to points and cells
    const pointData = [_]f64{ 0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 11.0 };
    const cellData = [_]f64{ 3.2, 4.3, 5.4, 6.5, 7.6, 8.7 };

    // Create tuples with (name, association, number of components, data) for each data set
    const dataSets = [_]VtuWriter.DataSet{
        .{ "Temperature", VtuWriter.DataSetType.PointData, 1, &pointData },
        .{ "Conductivity", VtuWriter.DataSetType.CellData, 1, &cellData },
    };

    std.log.info("Running VTU AsciiWriter...", .{});
    try VtuWriter.writeVtu(allocator, "test_ascii.vtu", mesh, &dataSets, .ascii);
    std.log.info("Finished running VTU AsciiWriter\n", .{});

    std.log.info("Running VTU CompressedRawBinaryWriter...", .{});
    try VtuWriter.writeVtu(allocator, "test_binary.vtu", mesh, &dataSets, .rawbinarycompressed);
    std.log.info("Finished running VTU CompressedRawBinaryWriter\n", .{});
}
