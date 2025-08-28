const std = @import("std");

const VtuWriter = @import("vtu_writer");

const mesh = blk: {
    const phi = 1.61803398875;
    const x_tl = 0.0; // x_tl is the translation value in the x coordinate
    const y_tl = 0.0; // y_tl is the translation value in the y coordinate
    const z_tl = 0.0; // z_tl is the translation value in the z coordinate

    const points = [_]f64{
        (0.0 + x_tl), (1.0 + y_tl), (phi + z_tl), // 0
        (0.0 + x_tl), (1.0 + y_tl), (-phi + z_tl), // 1
        (0.0 + x_tl), (-1.0 + y_tl), (phi + z_tl), // 2
        (0.0 + x_tl), (-1.0 + y_tl), (-phi + z_tl), // 3
        (1.0 + x_tl), (phi + y_tl), (0.0 + z_tl), // 4
        (1.0 + x_tl), (-phi + y_tl), (0.0 + z_tl), // 5
        (-1.0 + x_tl), (phi + y_tl), (0.0 + z_tl), // 6
        (-1.0 + x_tl), (-phi + y_tl), (0.0 + z_tl), // 7
        (phi + x_tl), (0.0 + y_tl), (1.0 + z_tl), // 8
        (phi + x_tl), (0.0 + y_tl), (-1.0 + z_tl), // 9
        (-phi + x_tl), (0.0 + y_tl), (1.0 + z_tl), // 10
        (-phi + x_tl), (0.0 + y_tl), (-1.0 + z_tl), // 11
        (0.0 + x_tl), (0.0 + y_tl), (0.0 + z_tl), // 12
        (0.0 + x_tl), (0.0 + y_tl), (-phi + z_tl), // 13
        (-1.0 + x_tl), (-1.0 + y_tl), (-4.0 + z_tl), // 14
        (1.0 + x_tl), (1.0 + y_tl), (-4.0 + z_tl), // 15
        (1.0 + x_tl), (-1.0 + y_tl), (-4.0 + z_tl), // 16
        (-1.0 + x_tl), (1.0 + y_tl), (-4.0 + z_tl), // 1715
    };

    const connectivity = [_]VtuWriter.IndexType{
        0, 2, 8, 12, // 0
        0, 2, 10, 12, // 1
        0, 4, 6, 12, // 2
        0, 4, 8, 12, // 3
        0, 6, 10, 12, // 4
        1, 3, 9, 12, // 5
        1, 3, 11, 12, // 6
        1, 4, 6, 12, // 7
        1, 4, 9, 12, // 8
        1, 6, 11, 12, // 9
        2, 5, 8, 12, // 10
        2, 7, 5, 12, // 11
        2, 7, 10, 12, // 12
        3, 5, 7, 12, // 13
        3, 5, 9, 12, // 14
        3, 7, 11, 12, // 15
        4, 8, 9, 12, // 16
        5, 8, 9, 12, // 17
        6, 10, 11, 12, // 18
        7, 10, 11, 12, // 19
        17, 15, 16, 14, 13, // 20 Pyramid
    };

    const offsets = [_]VtuWriter.IndexType{
        4, 8, 12, 16, 20, 24, 28, 32, 36, 40, 44, //
        48, 52, 56, 60, 64, 68, 72, 76, 80, 85, //
    };
    const types = [_]VtuWriter.CellType{
        .VTK_TETRA, .VTK_TETRA, .VTK_TETRA, .VTK_TETRA, .VTK_TETRA, .VTK_TETRA, .VTK_TETRA, .VTK_TETRA, .VTK_TETRA, .VTK_TETRA,   .VTK_TETRA,
        .VTK_TETRA, .VTK_TETRA, .VTK_TETRA, .VTK_TETRA, .VTK_TETRA, .VTK_TETRA, .VTK_TETRA, .VTK_TETRA, .VTK_TETRA, .VTK_PYRAMID,
    };

    break :blk VtuWriter.UnstructuredMesh{
        .points = &points,
        .connectivity = &connectivity,
        .offsets = &offsets,
        .types = &types,
    };
};

const dataSets = blk: {
    const pointData1 = [_]f64{
        100.0, 100.0, 100.0, 100.0, 0.0, 0.0, 0.0, 0.0, -100.0, -100.0, //
        -100.0, -100.0, 0.0, -100.0, 0.0, 0.0, 0.0, 0.0, 0.0, //
    };
    const pointData2 = [_]f64{
        1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, //
        1.0, 1.0, 0.0, 1.0, -1.0, -1.0, -1.0, -1.0, //
    };
    const cellHeight1 = [_]f64{
        -1.0, 1.0, -1.0, 1.0, -1.0, 1.0, -1.0, 1.0, -1.0, 1.0, //
        -1.0, 1.0, -1.0, 1.0, -1.0, 1.0, -1.0, 1.0, -1.0, 1.0,
        0, //
    };
    const cellHeight2 = [_]f64{
        1.0, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, //
        13, 14, 15, 16, 17, 18, 19, 20, 0, //
    };

    break :blk [_]VtuWriter.DataSet{
        .{ "Point_Data_1", VtuWriter.DataSetType.PointData, 1, &pointData1 },
        .{ "Point_Data_2", VtuWriter.DataSetType.PointData, 1, &pointData2 },
        .{ "Cell_Height_1", VtuWriter.DataSetType.CellData, 1, &cellHeight1 },
        .{ "Cell_Height_2", VtuWriter.DataSetType.CellData, 1, &cellHeight2 },
    };
};

test "icosahedron3D_test ascii" {
    const allocator = std.testing.allocator;

    try VtuWriter.writeVtu(allocator, "icosahedron_3D_ascii.vtu", mesh, &dataSets, .ascii);

    const expected_data = @embedFile("testfiles/icosahedron_3D/ascii.vtu");
    const written_data = try std.fs.cwd().readFileAlloc(allocator, "icosahedron_3D_ascii.vtu", std.math.maxInt(usize));
    defer allocator.free(written_data);

    std.debug.assert(std.mem.eql(u8, written_data, expected_data));
}

test "icosahedron3D_test raw_compressed" {
    const allocator = std.testing.allocator;

    try VtuWriter.writeVtu(allocator, "icosahedron_3D_raw_compressed.vtu", mesh, &dataSets, .rawbinarycompressed);

    const expected_data = @embedFile("testfiles/icosahedron_3D/raw_compressed.vtu");
    const written_data = try std.fs.cwd().readFileAlloc(allocator, "icosahedron_3D_raw_compressed.vtu", std.math.maxInt(usize));
    defer allocator.free(written_data);

    std.debug.assert(std.mem.eql(u8, written_data, expected_data));
}
