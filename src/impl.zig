const std = @import("std");

const Vtu = @import("types.zig");
const Utils = @import("utils.zig");

pub const AsciiWriter = @import("ascii_writer.zig").AsciiWriter;
pub const CompressedRawBinaryWriter = @import("zlib_writer.zig").CompressedRawBinaryWriter;

pub const VtuWriter = union(Vtu.WriteMode) {
    ascii: *AsciiWriter,
    rawbinarycompressed: *CompressedRawBinaryWriter,

    pub fn addHeaderAttributes(self: VtuWriter, attributes: *Vtu.Attributes) !void {
        switch (self) {
            inline else => |s| try s.addHeaderAttributes(attributes),
        }
    }

    pub fn addDataAttributes(self: VtuWriter, attributes: *Vtu.Attributes) !void {
        switch (self) {
            inline else => |s| try s.addDataAttributes(attributes),
        }
    }

    pub fn getAppendedAttributes(self: VtuWriter) []const Vtu.Attribute {
        switch (self) {
            inline else => |s| return s.getAppendedAttributes(),
        }
    }

    pub fn writeData(self: VtuWriter, dataType: type, data: []const dataType, fileWriter: *std.io.Writer) !void {
        switch (self) {
            inline else => |s| try s.writeData(dataType, data, fileWriter),
        }
    }

    pub fn writeAppended(self: VtuWriter, fileWriter: *std.io.Writer) !void {
        switch (self) {
            inline else => |s| try s.writeAppended(fileWriter),
        }
    }
};

pub fn writeVtu(
    allocator: std.mem.Allocator,
    filename: []const u8,
    mesh: Vtu.UnstructuredMesh,
    dataSets: []const Vtu.DataSet,
    vtuWriter: VtuWriter,
) !void {
    const cwd = std.fs.cwd();
    const output = try cwd.createFile(filename, .{});
    defer output.close();

    var fileBuffer: [1024]u8 = undefined;
    var fileWriter = output.writer(&fileBuffer);
    const file = &fileWriter.interface;
    try file.print("<?xml version=\"1.0\"?>\n", .{});

    var headerAttributes = try Vtu.Attributes.initCapacity(allocator, 3);
    defer headerAttributes.deinit();

    try headerAttributes.appendSlice(&.{
        .{ "byte_order", .{ .str = Utils.endianness() } },
        .{ "type", .{ .str = "UnstructuredGrid" } },
        .{ "version", .{ .str = "0.1" } },
    });
    try vtuWriter.addHeaderAttributes(&headerAttributes);

    Utils.openXmlScope(file, "VTKFile", headerAttributes.items()) catch std.log.warn("unable to write to file", .{});
    defer {
        Utils.closeXmlScope(file, "VTKFile") catch std.log.warn("unable to write to file", .{});
        file.flush() catch unreachable; // this is the end of the file
    }

    try writeContent(allocator, vtuWriter, mesh, dataSets, file);
}

fn writeContent(
    allocator: std.mem.Allocator,
    vtuWriter: VtuWriter,
    mesh: Vtu.UnstructuredMesh,
    dataSets: []const Vtu.DataSet,
    fileWriter: *std.io.Writer,
) !void {
    {
        Utils.openXmlScope(fileWriter, "UnstructuredGrid", &.{}) catch std.log.warn("unable to write to file", .{});
        defer Utils.closeXmlScope(fileWriter, "UnstructuredGrid") catch std.log.warn("unable to write to file", .{});

        {
            const pieceAttributes = [_]Vtu.Attribute{
                .{ "NumberOfPoints", .{ .int = @intCast(mesh.numberOfPoints()) } },
                .{ "NumberOfCells", .{ .int = @intCast(mesh.numberOfCells()) } },
            };
            Utils.openXmlScope(fileWriter, "Piece", &pieceAttributes) catch std.log.warn("unable to write to file", .{});
            defer Utils.closeXmlScope(fileWriter, "Piece") catch std.log.warn("unable to write to file", .{});

            {
                Utils.openXmlScope(fileWriter, "PointData", &.{}) catch std.log.warn("unable to write to file", .{});
                defer Utils.closeXmlScope(fileWriter, "PointData") catch std.log.warn("unable to write to file", .{});
                try writeDataSets(allocator, vtuWriter, dataSets, Vtu.DataSetType.PointData, fileWriter);
            }

            {
                Utils.openXmlScope(fileWriter, "CellData", &.{}) catch std.log.warn("unable to write to file", .{});
                defer Utils.closeXmlScope(fileWriter, "CellData") catch std.log.warn("unable to write to file", .{});
                try writeDataSets(allocator, vtuWriter, dataSets, Vtu.DataSetType.CellData, fileWriter);
            }

            {
                Utils.openXmlScope(fileWriter, "Points", &.{}) catch std.log.warn("unable to write to file", .{});
                defer Utils.closeXmlScope(fileWriter, "Points") catch std.log.warn("unable to write to file", .{});
                try writeDataSet(allocator, vtuWriter, "", Vtu.UnstructuredMesh.DIMENSION, f64, mesh.points, fileWriter);
            }

            {
                Utils.openXmlScope(fileWriter, "Cells", &.{}) catch std.log.warn("unable to write to file", .{});
                defer Utils.closeXmlScope(fileWriter, "Cells") catch std.log.warn("unable to write to file", .{});
                try writeDataSet(allocator, vtuWriter, "connectivity", 1, Vtu.IndexType, mesh.connectivity, fileWriter);
                try writeDataSet(allocator, vtuWriter, "offsets", 1, Vtu.IndexType, mesh.offsets, fileWriter);
                try writeDataSet(allocator, vtuWriter, "types", 1, Vtu.CellType, mesh.types, fileWriter);
            }
        }
    }

    const appendedAttributes = vtuWriter.getAppendedAttributes();
    if (appendedAttributes.len > 0) {
        Utils.openXmlScope(fileWriter, "AppendedData", appendedAttributes) catch std.log.warn("unable to write to file", .{});
        defer Utils.closeXmlScope(fileWriter, "AppendedData") catch std.log.warn("unable to write to file", .{});
        fileWriter.print("_", .{}) catch std.log.warn("unable to write to file", .{});
        vtuWriter.writeAppended(fileWriter) catch std.log.warn("unable to write to file", .{});
    }
}

fn getDataSetHeader(
    allocator: std.mem.Allocator,
    vtuWriter: VtuWriter,
    name: []const u8,
    ncomponents: usize,
    dataType: type,
) !Vtu.Attributes {
    var attributes = try Vtu.Attributes.initCapacity(allocator, 5);

    try attributes.append(.{ "type", .{ .str = Utils.dataTypeString(dataType) } });

    if (!std.mem.eql(u8, name, "")) {
        try attributes.append(.{ "Name", .{ .str = name } });
    }

    if (ncomponents > 1) {
        try attributes.append(.{ "NumberOfComponents", .{ .int = @intCast(ncomponents) } });
    }

    try vtuWriter.addDataAttributes(&attributes);

    return attributes;
}

fn writeDataSet(
    allocator: std.mem.Allocator,
    vtuWriter: VtuWriter,
    name: []const u8,
    ncomponents: usize,
    dataType: type,
    data: []const dataType,
    fileWriter: *std.io.Writer,
) !void {
    var attributes = try getDataSetHeader(allocator, vtuWriter, name, ncomponents, dataType);
    defer attributes.deinit();

    var appended = false;
    for (attributes.items()) |attribute| {
        if (std.mem.eql(u8, attribute[0], "format")) {
            switch (attribute[1]) {
                .str => |format| {
                    if (std.mem.eql(u8, format, "appended")) {
                        appended = true;
                    }
                },
                else => {},
            }
        }
    }

    if (appended) {
        Utils.emptyXmlScope(fileWriter, "DataArray", attributes.items()) catch std.log.warn("unable to write to file", .{});
        vtuWriter.writeData(dataType, data, fileWriter) catch std.log.warn("unable to write to file", .{});
    } else {
        Utils.openXmlScope(fileWriter, "DataArray", attributes.items()) catch std.log.warn("unable to write to file", .{});
        defer Utils.closeXmlScope(fileWriter, "DataArray") catch std.log.warn("unable to write to file", .{});
        vtuWriter.writeData(dataType, data, fileWriter) catch std.log.warn("unable to write to file", .{});
    }
}

fn writeDataSets(
    allocator: std.mem.Allocator,
    vtuWriter: VtuWriter,
    dataSets: []const Vtu.DataSet,
    dataSetType: Vtu.DataSetType,
    fileWriter: *std.io.Writer,
) !void {
    for (dataSets) |dataSet| {
        if (dataSet[1] == dataSetType) {
            try writeDataSet(
                allocator,
                vtuWriter,
                dataSet[0],
                dataSet[2],
                @TypeOf(dataSet[3][0]),
                dataSet[3],
                fileWriter,
            );
        }
    }
}
