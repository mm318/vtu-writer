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

pub const Byte = u8;
pub const HeaderType = usize;
pub const IndexType = i64;
pub const CellType = enum(i8) {
    VTK_QUAD = 9,
    VTK_TETRA = 10,
    VTK_VOXEL = 11,
    VTK_HEXAHEDRON = 12,
    VTK_PYRAMID = 14,
};

pub fn numCellPoints(cell_type: CellType) usize {
    return switch (cell_type) {
        .VTK_QUAD => 4,
        .VTK_TETRA => 4,
        .VTK_VOXEL => 8,
        .VTK_HEXAHEDRON => 8,
        .VTK_PYRAMID => 5,
    };
}

pub const UnstructuredMesh = struct {
    pub const DIMENSION = 3;
    points: []const f64,
    connectivity: []const IndexType,
    offsets: []const IndexType,
    types: []const CellType,

    pub fn numberOfPoints(self: UnstructuredMesh) usize {
        return self.points.len / DIMENSION;
    }

    pub fn numberOfCells(self: UnstructuredMesh) usize {
        return self.types.len;
    }
};

pub const DataSetType = enum {
    PointData,
    CellData,
};

const DataSetData = []const f64;

pub const DataSet = struct {
    []const u8,
    DataSetType,
    usize,
    DataSetData,
};
