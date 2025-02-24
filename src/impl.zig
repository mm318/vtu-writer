const std = @import("std");

const Vtu = @import("types.zig");
const Utils = @import("utils.zig");

pub const AsciiWriter = struct {
    pub fn init() AsciiWriter {
        return .{};
    }

    pub fn addHeaderAttributes(self: *const AsciiWriter, attributes: *Vtu.Attributes) !void {
        _ = self;
        _ = attributes;
    }

    pub fn addDataAttributes(self: *const AsciiWriter, attributes: *Vtu.Attributes) !void {
        _ = self;
        const dataAttributes = [_]Vtu.Attribute{
            .{ "format", .{ .str = "ascii" } },
        };
        try attributes.appendSlice(&dataAttributes);
    }

    pub fn writeData(
        self: *const AsciiWriter,
        dataType: type,
        data: []const dataType,
        fileWriter: std.fs.File.Writer,
    ) !void {
        _ = self;
        for (data) |datum| {
            try fileWriter.print("{d} ", .{datum});
        }
        try fileWriter.print("\n", .{});
    }
};

pub const CompressedRawBinaryWriter = struct {
    offset: usize,

    pub fn init() CompressedRawBinaryWriter {
        return .{ .offset = 0 };
    }

    pub fn addHeaderAttributes(self: *const CompressedRawBinaryWriter, attributes: *Vtu.Attributes) !void {
        _ = self;
        const headerAttributes = [_]Vtu.Attribute{
            .{ "header_type", .{ .str = Utils.dataTypeString(Vtu.HeaderType) } },
            .{ "compressor", .{ .str = "vtkZLibDataCompressor" } },
        };
        try attributes.appendSlice(&headerAttributes);
    }

    pub fn addDataAttributes(self: *const CompressedRawBinaryWriter, attributes: *Vtu.Attributes) !void {
        const dataAttributes = [_]Vtu.Attribute{
            .{ "format", .{ .str = "appended" } },
            .{ "offset", .{ .int = @intCast(self.offset) } },
        };
        try attributes.appendSlice(&dataAttributes);
    }

    pub fn writeData(
        self: *const CompressedRawBinaryWriter,
        dataType: type,
        data: []const dataType,
        fileWriter: std.fs.File.Writer,
    ) !void {
        _ = self;
        _ = data;
        _ = fileWriter;
    }
};

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

    pub fn writeData(self: VtuWriter, dataType: type, data: []const dataType, fileWriter: std.fs.File.Writer) !void {
        switch (self) {
            inline else => |s| try s.writeData(dataType, data, fileWriter),
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

    try output.writer().print("<?xml version=\"1.0\"?>\n", .{});

    var headerAttributes = Vtu.Attributes.init(allocator);
    defer headerAttributes.deinit();

    try headerAttributes.appendSlice(&.{
        .{ "byte_order", .{ .str = Utils.endianness() } },
        .{ "type", .{ .str = "UnstructuredGrid" } },
        .{ "version", .{ .str = "0.1" } },
    });
    try vtuWriter.addHeaderAttributes(&headerAttributes);

    Utils.openXmlScope(output.writer(), "VTKFile", headerAttributes.items) catch std.log.warn("unable to write to file", .{});
    defer Utils.closeXmlScope(output.writer(), "VTKFile") catch std.log.warn("unable to write to file", .{});

    try writeContent(allocator, vtuWriter, mesh, dataSets, output.writer());
}

fn writeContent(
    allocator: std.mem.Allocator,
    vtuWriter: VtuWriter,
    mesh: Vtu.UnstructuredMesh,
    dataSets: []const Vtu.DataSet,
    fileWriter: std.fs.File.Writer,
) !void {
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

fn getDataSetHeader(
    allocator: std.mem.Allocator,
    vtuWriter: VtuWriter,
    name: []const u8,
    ncomponents: usize,
    dataType: type,
) !Vtu.Attributes {
    var attributes = Vtu.Attributes.init(allocator);

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
    fileWriter: std.fs.File.Writer,
) !void {
    const attributes = try getDataSetHeader(allocator, vtuWriter, name, ncomponents, dataType);
    defer attributes.deinit();

    var appended = false;
    for (attributes.items) |attribute| {
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
        Utils.emptyXmlScope(fileWriter, "DataArray", attributes.items) catch std.log.warn("unable to write to file", .{});
        vtuWriter.writeData(dataType, data, fileWriter) catch std.log.warn("unable to write to file", .{});
    } else {
        Utils.openXmlScope(fileWriter, "DataArray", attributes.items) catch std.log.warn("unable to write to file", .{});
        defer Utils.closeXmlScope(fileWriter, "DataArray") catch std.log.warn("unable to write to file", .{});
        vtuWriter.writeData(dataType, data, fileWriter) catch std.log.warn("unable to write to file", .{});
    }
}

fn writeDataSets(
    allocator: std.mem.Allocator,
    vtuWriter: VtuWriter,
    dataSets: []const Vtu.DataSet,
    dataSetType: Vtu.DataSetType,
    fileWriter: std.fs.File.Writer,
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
