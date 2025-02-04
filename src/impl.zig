const std = @import("std");

const Vtu = @import("types.zig");
const Utils = @import("utils.zig");

const VtuWriter = struct {
    fn init() VtuWriter {
        return .{};
    }

    fn addHeaderAttributes(self: VtuWriter, attributes: []const Utils.Attribute) void {
        _ = self;
        _ = attributes;
    }
};
pub const AsciiWriter = struct {
    writer: VtuWriter,

    pub fn init() AsciiWriter {
        return .{ .writer = VtuWriter.init() };
    }
};
pub const CompressedRawBinaryWriter = struct {
    writer: VtuWriter,

    pub fn init() CompressedRawBinaryWriter {
        return .{ .writer = VtuWriter.init() };
    }
};

pub fn writeVtu(
    allocator: std.mem.Allocator,
    filename: []const u8,
    mesh: Vtu.UnstructuredMesh,
    dataSetInfo: []const Vtu.DataSetInfo,
    dataSetData: []const Vtu.DataSetData,
    vtuWriter: VtuWriter,
) !void {
    const cwd = std.fs.cwd();
    const output = try cwd.createFile(filename, .{});
    defer output.close();

    try output.writer().print("<?xml version=\"1.0\"?>\n", .{});

    const headerAttributes = [_]Utils.Attribute{
        .{ "byte_order", .{ .str = Utils.endianness() } },
        .{ "type", .{ .str = "UnstructuredGrid" } },
        .{ "version", .{ .str = "0.1" } },
    };

    vtuWriter.addHeaderAttributes(&headerAttributes);

    try Utils.openXmlScope(output.writer(), "VTKFile", &headerAttributes);
    defer Utils.closeXmlScope(output.writer(), "VTKFile") catch std.log.warn("unable to write to file", .{});

    try writeContent(allocator, output.writer(), mesh, dataSetInfo, dataSetData, vtuWriter);
}

fn writeContent(
    allocator: std.mem.Allocator,
    fileWriter: std.fs.File.Writer,
    mesh: Vtu.UnstructuredMesh,
    dataSetInfo: []const Vtu.DataSetInfo,
    dataSetData: []const Vtu.DataSetData,
    vtuWriter: VtuWriter,
) !void {
    _ = allocator;
    _ = dataSetInfo;
    _ = dataSetData;
    _ = vtuWriter;

    {
        try Utils.openXmlScope(fileWriter, "UnstructuredGrid", &.{});
        defer Utils.closeXmlScope(fileWriter, "UnstructuredGrid") catch std.log.warn("unable to write to file", .{});

        {
            const pieceAttributes = [_]Utils.Attribute{
                .{ "NumberOfPoints", .{ .int = @intCast(mesh.numberOfPoints()) } },
                .{ "NumberOfCells", .{ .int = @intCast(mesh.numberOfCells()) } },
            };

            try Utils.openXmlScope(fileWriter, "Piece", &pieceAttributes);
            defer Utils.closeXmlScope(fileWriter, "Piece") catch std.log.warn("unable to write to file", .{});

            {
                try Utils.openXmlScope(fileWriter, "Points", &.{});
                defer Utils.closeXmlScope(fileWriter, "Points") catch std.log.warn("unable to write to file", .{});

                // writeDataSets(pointData)
            }

            {
                try Utils.openXmlScope(fileWriter, "Cells", &.{});
                defer Utils.closeXmlScope(fileWriter, "Cells") catch std.log.warn("unable to write to file", .{});

                // writeDataSets(pointData)
            }

            {
                try Utils.openXmlScope(fileWriter, "PointData", &.{});
                defer Utils.closeXmlScope(fileWriter, "PointData") catch std.log.warn("unable to write to file", .{});

                // writeDataSets(pointData)
            }

            {
                try Utils.openXmlScope(fileWriter, "CellData", &.{});
                defer Utils.closeXmlScope(fileWriter, "CellData") catch std.log.warn("unable to write to file", .{});

                // writeDataSets(cellData)
            }
        }
    }
}
