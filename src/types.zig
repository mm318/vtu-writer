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

pub const HeaderType = usize;

pub const IndexType = i64;
pub const CellType = i8;

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
