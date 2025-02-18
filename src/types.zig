const std = @import("std");

pub const WriteMode = enum {
    ascii,
    rawbinarycompressed,
};

pub const AttributeValueType = union(enum) {
    bool: bool,
    int: i32,
    float: f32,
    str: []const u8,
};

pub const Attribute = struct { []const u8, AttributeValueType };

pub const Attributes = std.ArrayList(Attribute);

pub const Writer = struct {
    addHeaderAttributesFn: *const fn (ptr: *const Writer, attributes: *Attributes) std.mem.Allocator.Error!void,
    addDataAttributesFn: *const fn (ptr: *const Writer, attributes: *Attributes) std.mem.Allocator.Error!void,

    pub fn addHeaderAttributes(self: *const Writer, attributes: *Attributes) std.mem.Allocator.Error!void {
        try self.addHeaderAttributesFn(self, attributes);
    }

    pub fn addDataAttributes(self: *const Writer, attributes: *Attributes) std.mem.Allocator.Error!void {
        try self.addDataAttributesFn(self, attributes);
    }
};

pub const HeaderType = usize;

const CellType = i8;
const IndexType = i64;

pub const UnstructuredMesh = struct {
    points: []const f64,
    connectivity: []const IndexType,
    offsets: []const IndexType,
    types: []const CellType,

    pub fn numberOfPoints(self: UnstructuredMesh) usize {
        return self.points.len;
    }

    pub fn numberOfCells(self: UnstructuredMesh) usize {
        return self.types.len;
    }
};

pub const DataSetType = enum {
    PointData,
    CellData,
};

pub const DataSetInfo = struct {
    []const u8,
    DataSetType,
    usize,
};

pub const DataSetData = []const f64;
