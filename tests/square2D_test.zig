const std = @import("std");

const VtuWriter = @import("vtu_writer");

const mesh = blk: {
    const points = [_]f64{
        0.0, 0.0, 0.5, 0.0, 0.3, 0.5, 0.0, 0.7, 0.5, 0.0, 1.0, 0.5, // 0,  1,  2,  3
        0.5, 0.0, 0.5, 0.5, 0.3, 0.5, 0.5, 0.7, 0.5, 0.5, 1.0, 0.5, // 4,  5,  6,  7
        1.0, 0.0, 0.5, 1.0, 0.3, 0.5, 1.0, 0.7, 0.5, 1.0, 1.0, 0.5, // 8,  9, 10, 11
    };

    const connectivity = [_]VtuWriter.IndexType{
        0, 4, 5, 1, // 0
        1, 5, 6, 2, // 1
        2, 6, 7, 3, // 2
        4, 8, 9, 5, // 3
        5, 9, 10, 6, // 4
        6, 10, 11, 7, // 5
    };

    const offsets = [_]VtuWriter.IndexType{ 4, 8, 12, 16, 20, 24 };
    const types = [_]VtuWriter.CellType{ .VTK_QUAD, .VTK_QUAD, .VTK_QUAD, .VTK_QUAD, .VTK_QUAD, .VTK_QUAD };

    break :blk VtuWriter.UnstructuredMesh{
        .points = &points,
        .connectivity = &connectivity,
        .offsets = &offsets,
        .types = &types,
    };
};

const dataSets = blk: {
    const pointData1 = [_]f64{ 0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 11.0 };
    const pointData2 = [_]f64{ 0.1, -0.2, 0.3, -0.4, 0.5, 0.6, -0.7, 0.8, 0.9, 1.0, 1.1, -1.2 };
    const cellData1 = [_]f64{ 3.2, 4.3, 5.4, 6.5, 7.6, 8.7 };
    const cellData2 = [_]f64{ 1.0, -1.0, 1.0, -1.0, 1.0, -1.0 };
    const cellData3 = cellData1;

    break :blk [_]VtuWriter.DataSet{
        .{ "pointData1", VtuWriter.DataSetType.PointData, 1, &pointData1 },
        .{ "pointData2", VtuWriter.DataSetType.PointData, 1, &pointData2 },
        .{ "cellData1", VtuWriter.DataSetType.CellData, 1, &cellData1 },
        .{ "cellData2", VtuWriter.DataSetType.CellData, 1, &cellData2 },
        .{ "cellData3", VtuWriter.DataSetType.CellData, 1, &cellData3 },
    };
};

test "square2D_test ascii" {
    const allocator = std.testing.allocator;

    try VtuWriter.writeVtu(allocator, "square_2D_ascii.vtu", mesh, &dataSets, .ascii);

    const expected_data = @embedFile("testfiles/square_2D/ascii.vtu");
    const written_data = try std.fs.cwd().readFileAlloc(allocator, "square_2D_ascii.vtu", std.math.maxInt(usize));
    defer allocator.free(written_data);

    std.debug.assert(std.mem.eql(u8, written_data, expected_data));
}

test "square2D_test raw_compressed" {
    const allocator = std.testing.allocator;

    try VtuWriter.writeVtu(allocator, "square_2D_raw_compressed.vtu", mesh, &dataSets, .rawbinarycompressed);

    const expected_data = @embedFile("testfiles/square_2D/raw_compressed.vtu");
    const written_data = try std.fs.cwd().readFileAlloc(allocator, "square_2D_raw_compressed.vtu", std.math.maxInt(usize));
    defer allocator.free(written_data);

    std.debug.assert(std.mem.eql(u8, written_data, expected_data));
}
