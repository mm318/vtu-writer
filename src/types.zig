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

pub const WriteMode = enum {
    ascii,
    rawbinarycompressed,
};
