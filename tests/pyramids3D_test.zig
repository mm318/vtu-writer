const std = @import("std");

const VtuWriter = @import("vtu_writer");

const mesh = blk: {
    const points = [_]f64{
        0.0, 0.0, 0.0, 0.0, 3.0, 0.0, 1.0, 2.0, 2.0, // 0, 1, 2
        1.0, 3.0, -2.0, -2.0, 2.0, 0.0, -1.0, 1.0, 2.0, // 3, 4, 5
        2.0, -2.0, -2.0, 2.0, -2.0, 2.0, -2.0, -2.0, 2.0, // 6, 7, 8
        -2.0, -2.0, -2.0, // 9
    };

    const connectivity = [_]VtuWriter.IndexType{
        5, 0, 1, 2, // 0
        2, 0, 1, 3, // 1
        3, 0, 1, 4, // 2
        4, 0, 1, 5, // 3
        8, 7, 6, 9, 0, // 4  --> Pyramid
    };

    const offsets = [_]VtuWriter.IndexType{ 4, 8, 12, 16, 21 };
    const types = [_]VtuWriter.CellType{ 10, 10, 10, 10, 14 };

    break :blk VtuWriter.UnstructuredMesh{
        .points = &points,
        .connectivity = &connectivity,
        .offsets = &offsets,
        .types = &types,
    };
};

const dataSets = blk: {
    const flashStrengthPoints = [_]f64{ 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 0.0, 0.0, 0.0 };
    const cellColour = [_]f64{ 1.0, 2.0, 3.0, 4.0, 0.0 };

    break :blk [_]VtuWriter.DataSet{
        .{ "Flash Strength Points", VtuWriter.DataSetType.PointData, 1, &flashStrengthPoints },
        .{ "Cell Colour", VtuWriter.DataSetType.CellData, 1, &cellColour },
    };
};

test "pyramids3D_test ascii" {
    const allocator = std.testing.allocator;

    try VtuWriter.writeVtu(allocator, "pyramids_3D_ascii.vtu", mesh, &dataSets, .ascii);

    const expected_data = @embedFile("testfiles/pyramids_3D/ascii.vtu");
    const written_data = try std.fs.cwd().readFileAlloc(allocator, "pyramids_3D_ascii.vtu", std.math.maxInt(usize));
    defer allocator.free(written_data);

    std.debug.assert(std.mem.eql(u8, written_data, expected_data));
}

test "pyramids3D_test raw_compressed" {
    const allocator = std.testing.allocator;

    try VtuWriter.writeVtu(allocator, "pyramids_3D_raw_compressed.vtu", mesh, &dataSets, .rawbinarycompressed);

    const expected_data = @embedFile("testfiles/pyramids_3D/raw_compressed.vtu");
    const written_data = try std.fs.cwd().readFileAlloc(allocator, "pyramids_3D_raw_compressed.vtu", std.math.maxInt(usize));
    defer allocator.free(written_data);

    std.debug.assert(std.mem.eql(u8, written_data, expected_data));
}
