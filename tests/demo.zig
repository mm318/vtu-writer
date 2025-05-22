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

    var mesh_builder = VtuWriter.UnstructuredMeshBuilder.init(allocator);
    defer mesh_builder.deinit();

    try mesh_builder.reservePoints(12);
    try mesh_builder.reserveCells(.VTK_QUAD, 6);

    // Create data for 3x2 quad mesh: (x, y, z) coordinates of mesh vertices
    _ = try mesh_builder.addPoint(.{ 0.0, 0.0, 0.5 }); // point 0
    _ = try mesh_builder.addPoint(.{ 0.0, 0.3, 0.5 }); // point 1
    _ = try mesh_builder.addPoint(.{ 0.0, 0.7, 0.5 }); // point 2
    _ = try mesh_builder.addPoint(.{ 0.0, 1.0, 0.5 }); // point 3
    _ = try mesh_builder.addPoint(.{ 0.5, 0.0, 0.5 }); // point 4
    _ = try mesh_builder.addPoint(.{ 0.5, 0.3, 0.5 }); // point 5
    _ = try mesh_builder.addPoint(.{ 0.5, 0.7, 0.5 }); // point 6
    _ = try mesh_builder.addPoint(.{ 0.5, 1.0, 0.5 }); // point 7
    _ = try mesh_builder.addPoint(.{ 1.0, 0.0, 0.5 }); // point 8
    _ = try mesh_builder.addPoint(.{ 1.0, 0.3, 0.5 }); // point 9
    _ = try mesh_builder.addPoint(.{ 1.0, 0.7, 0.5 }); // point 10
    _ = try mesh_builder.addPoint(.{ 1.0, 1.0, 0.5 }); // point 11

    // Vertex indices of all cells
    try mesh_builder.addCell(.VTK_QUAD, .{ 0, 4, 5, 1 }); // cell 0
    try mesh_builder.addCell(.VTK_QUAD, .{ 1, 5, 6, 2 }); // cell 1
    try mesh_builder.addCell(.VTK_QUAD, .{ 2, 6, 7, 3 }); // cell 2
    try mesh_builder.addCell(.VTK_QUAD, .{ 4, 8, 9, 5 }); // cell 3
    try mesh_builder.addCell(.VTK_QUAD, .{ 5, 9, 10, 6 }); // cell 4
    try mesh_builder.addCell(.VTK_QUAD, .{ 6, 10, 11, 7 }); // cell 5

    const mesh = mesh_builder.getUnstructuredMesh();

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
