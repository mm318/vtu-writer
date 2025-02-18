const std = @import("std");

const Vtu = @import("types.zig");
const Utils = @import("utils.zig");

pub const AsciiWriter = struct {
    writer: Vtu.Writer,

    pub fn init() AsciiWriter {
        const VtuWriterImpl = struct {
            pub fn addHeaderAttributes(
                ptr: *const Vtu.Writer,
                attributes: *Vtu.Attributes,
            ) std.mem.Allocator.Error!void {
                const self: *const AsciiWriter = @fieldParentPtr("writer", ptr);
                try self.addHeaderAttributes(attributes);
            }

            pub fn addDataAttributes(
                ptr: *const Vtu.Writer,
                attributes: *Vtu.Attributes,
            ) std.mem.Allocator.Error!void {
                const self: *const AsciiWriter = @fieldParentPtr("writer", ptr);
                try self.addDataAttributes(attributes);
            }
        };
        return .{ .writer = .{
            .addHeaderAttributesFn = VtuWriterImpl.addHeaderAttributes,
            .addDataAttributesFn = VtuWriterImpl.addDataAttributes,
        } };
    }

    pub fn addHeaderAttributes(
        self: *const AsciiWriter,
        attributes: *Vtu.Attributes,
    ) std.mem.Allocator.Error!void {
        _ = self;
        _ = attributes;
    }

    pub fn addDataAttributes(
        self: *const AsciiWriter,
        attributes: *Vtu.Attributes,
    ) std.mem.Allocator.Error!void {
        _ = self;
        const dataAttributes = [_]Vtu.Attribute{
            .{ "format", .{ .str = "ascii" } },
        };
        try attributes.appendSlice(&dataAttributes);
    }
};

pub const CompressedRawBinaryWriter = struct {
    writer: Vtu.Writer,
    offset: usize,

    pub fn init() CompressedRawBinaryWriter {
        const VtuWriterImpl = struct {
            pub fn addHeaderAttributes(
                ptr: *const Vtu.Writer,
                attributes: *Vtu.Attributes,
            ) std.mem.Allocator.Error!void {
                const self: *const CompressedRawBinaryWriter = @fieldParentPtr("writer", ptr);
                try self.addHeaderAttributes(attributes);
            }

            pub fn addDataAttributes(
                ptr: *const Vtu.Writer,
                attributes: *Vtu.Attributes,
            ) std.mem.Allocator.Error!void {
                const self: *const CompressedRawBinaryWriter = @fieldParentPtr("writer", ptr);
                try self.addDataAttributes(attributes);
            }
        };
        return .{
            .writer = .{
                .addHeaderAttributesFn = VtuWriterImpl.addHeaderAttributes,
                .addDataAttributesFn = VtuWriterImpl.addDataAttributes,
            },
            .offset = 0,
        };
    }

    pub fn addHeaderAttributes(
        self: *const CompressedRawBinaryWriter,
        attributes: *Vtu.Attributes,
    ) std.mem.Allocator.Error!void {
        _ = self;
        const headerAttributes = [_]Vtu.Attribute{
            .{ "header_type", .{ .str = Utils.dataTypeString(Vtu.HeaderType) } },
            .{ "compressor", .{ .str = "vtkZLibDataCompressor" } },
        };
        try attributes.appendSlice(&headerAttributes);
    }

    pub fn addDataAttributes(
        self: *const CompressedRawBinaryWriter,
        attributes: *Vtu.Attributes,
    ) std.mem.Allocator.Error!void {
        const dataAttributes = [_]Vtu.Attribute{
            .{ "format", .{ .str = "appended" } },
            .{ "offset", .{ .int = @intCast(self.offset) } },
        };
        try attributes.appendSlice(&dataAttributes);
    }
};

pub fn writeVtu(
    allocator: std.mem.Allocator,
    filename: []const u8,
    mesh: Vtu.UnstructuredMesh,
    dataSetInfo: []const Vtu.DataSetInfo,
    dataSetData: []const Vtu.DataSetData,
    vtuWriter: *Vtu.Writer,
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

    try writeContent(allocator, vtuWriter, mesh, dataSetInfo, dataSetData, output.writer());
}

fn writeContent(
    allocator: std.mem.Allocator,
    vtuWriter: *Vtu.Writer,
    mesh: Vtu.UnstructuredMesh,
    dataSetInfo: []const Vtu.DataSetInfo,
    dataSetData: []const Vtu.DataSetData,
    fileWriter: std.fs.File.Writer,
) !void {
    _ = dataSetInfo;
    _ = dataSetData;

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
                Utils.openXmlScope(fileWriter, "Points", &.{}) catch std.log.warn("unable to write to file", .{});
                defer Utils.closeXmlScope(fileWriter, "Points") catch std.log.warn("unable to write to file", .{});
                try writeDataSet(allocator, vtuWriter, "", 3, f64, mesh.points, fileWriter);
            }

            {
                Utils.openXmlScope(fileWriter, "Cells", &.{}) catch std.log.warn("unable to write to file", .{});
                defer Utils.closeXmlScope(fileWriter, "Cells") catch std.log.warn("unable to write to file", .{});
                // writeDataSets(pointData)
            }

            {
                Utils.openXmlScope(fileWriter, "PointData", &.{}) catch std.log.warn("unable to write to file", .{});
                defer Utils.closeXmlScope(fileWriter, "PointData") catch std.log.warn("unable to write to file", .{});
                // writeDataSets(pointData)
            }

            {
                Utils.openXmlScope(fileWriter, "CellData", &.{}) catch std.log.warn("unable to write to file", .{});
                defer Utils.closeXmlScope(fileWriter, "CellData") catch std.log.warn("unable to write to file", .{});
                // writeDataSets(cellData)
            }
        }
    }
}

fn getDataSetHeader(
    allocator: std.mem.Allocator,
    vtuWriter: *Vtu.Writer,
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
    vtuWriter: *Vtu.Writer,
    name: []const u8,
    ncomponents: usize,
    dataType: type,
    data: []const dataType,
    fileWriter: std.fs.File.Writer,
) !void {
    _ = data;

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
        // vtuWriter.writeData(fileWriter, data);
    } else {
        Utils.openXmlScope(fileWriter, "DataArray", attributes.items) catch std.log.warn("unable to write to file", .{});
        defer Utils.closeXmlScope(fileWriter, "DataArray") catch std.log.warn("unable to write to file", .{});
        // vtuWriter.writeData(fileWriter, data);
    }
}
