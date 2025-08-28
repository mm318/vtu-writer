const std = @import("std");

const VtuWriter = @import("vtu_writer");

const mesh = blk: {
    const points = [_]f64{
        0.0, 0.0, 0.0, 5.0, 0.0, 0.0, 0.0, 5.0, 0.0, 5.0, 5.0, 0.0, // 0, 1, 2, 3
        0.0, 0.0, 5.0, 5.0, 0.0, 5.0, 0.0, 5.0, 5.0, 5.0, 5.0, 5.0, // 4, 5, 6, 7
        2.0, 2.0, 5.0, 7.0, 2.0, 5.0, 2.0, 7.0, 5.0, 7.0, 7.0, 5.0, // 8, 9, 10, 11
        2.0, 2.0, 10.0, 7.0, 2.0, 10.0, 2.0, 7.0, 10.0, 7.0, 7.0, 10.0, // 12, 13, 14, 15
    };

    const connectivity = [_]VtuWriter.IndexType{
        0, 1, 2, 3, 4, 5, 6, 7, // 0
        8, 9, 10, 11, 12, 13, 14, 15, // 1, hexahedra - cubes
    };

    const offsets = [_]VtuWriter.IndexType{ 8, 16 };
    const types = [_]VtuWriter.CellType{ .VTK_VOXEL, .VTK_VOXEL };

    break :blk VtuWriter.UnstructuredMesh{
        .points = &points,
        .connectivity = &connectivity,
        .offsets = &offsets,
        .types = &types,
    };
};

const dataSets = blk: {
    const pointData1 = [_]f64{
        1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, //
        1.0, 1.0, 1.0, 1.0, 1.0, 5.0, 5.0, 5.0, //
    };
    const pointData2 = [_]f64{
        41.0, 13.0, 16.0, 81.0, 51.0, 31.0, 18.0, 12.0, //
        19.0, 21.0, 11.0, 19.0, 16.0, 45.0, 35.0, 58.0, //
    };
    const cellData1 = [_]f64{ 1.0, 2.0 };
    const cellData2 = [_]f64{ 10.0, 20.0 };

    break :blk [_]VtuWriter.DataSet{
        .{ "Point_Data_1", VtuWriter.DataSetType.PointData, 1, &pointData1 },
        .{ "Point_Data_2", VtuWriter.DataSetType.PointData, 1, &pointData2 },
        .{ "Cell_1", VtuWriter.DataSetType.CellData, 1, &cellData1 },
        .{ "Cell_2", VtuWriter.DataSetType.CellData, 1, &cellData2 },
    };
};

test "hexahedras3D_test ascii" {
    const allocator = std.testing.allocator;

    try VtuWriter.writeVtu(allocator, "hexas_3D_ascii.vtu", mesh, &dataSets, .ascii);

    const expected_data = @embedFile("testfiles/hexas_3D/ascii.vtu");
    const written_data = try std.fs.cwd().readFileAlloc(allocator, "hexas_3D_ascii.vtu", std.math.maxInt(usize));
    defer allocator.free(written_data);

    std.debug.assert(std.mem.eql(u8, written_data, expected_data));
}

test "hexahedras3D_test raw_compressed" {
    const allocator = std.testing.allocator;

    try VtuWriter.writeVtu(allocator, "hexas_3D_raw_compressed.vtu", mesh, &dataSets, .rawbinarycompressed);

    const expected_data = @embedFile("testfiles/hexas_3D/raw_compressed.vtu");
    const written_data = try std.fs.cwd().readFileAlloc(allocator, "hexas_3D_raw_compressed.vtu", std.math.maxInt(usize));
    defer allocator.free(written_data);

    std.debug.assert(std.mem.eql(u8, written_data, expected_data));
}
