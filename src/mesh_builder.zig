const std = @import("std");

const Vtu = @import("types.zig");

const UnstructuredMeshBuilder = @This();

const Point = [Vtu.UnstructuredMesh.DIMENSION]f64;

points: std.ArrayList(f64),
connectivity: std.ArrayList(Vtu.IndexType),
connectivity_offsets: std.ArrayList(Vtu.IndexType),
cell_types: std.ArrayList(Vtu.CellType),

pub fn init(allocator: std.mem.Allocator) UnstructuredMeshBuilder {
    return .{
        .points = std.ArrayList(f64).init(allocator),
        .connectivity = std.ArrayList(Vtu.IndexType).init(allocator),
        .connectivity_offsets = std.ArrayList(Vtu.IndexType).init(allocator),
        .cell_types = std.ArrayList(Vtu.CellType).init(allocator),
    };
}

pub fn reservePoints(self: *UnstructuredMeshBuilder, num_points: usize) void {
    const add_capacity = (num_points * Vtu.UnstructuredMesh.DIMENSION);
    self.points.ensureTotalCapacity(self.points.items.len + add_capacity);
}

pub fn reserveCells(
    self: *UnstructuredMeshBuilder,
    cell_type: Vtu.CellType,
    num_cells: usize,
) void {
    const add_capacity = (num_cells * Vtu.numCellPoints(cell_type));
    self.connectivity.ensureTotalCapacity(self.connectivity.items.len + add_capacity);
    self.connectivity_offsets.ensureTotalCapacity(self.connectivity_offsets.items.len + num_cells);
    self.cell_types.ensureTotalCapacity(self.cell_types.items.len + num_cells);
}

pub fn addPoint(self: *UnstructuredMeshBuilder, point: Point) Vtu.IndexType {
    const point_idx = self.points.items.len / Vtu.UnstructuredMesh.DIMENSION;
    self.points.appendSlice(point);
    return point_idx;
}

pub fn addCell(
    self: *UnstructuredMeshBuilder,
    comptime cell_type: Vtu.CellType,
    point_idxs: [Vtu.numCellPoints(cell_type)]Vtu.IndexType,
) void {
    self.connectivity.appendSlice(point_idxs);
    self.connectivity_offsets.append(self.connectivity.items.len);
    self.cell_types.append(cell_type);
}
