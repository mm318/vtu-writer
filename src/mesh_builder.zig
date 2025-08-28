const std = @import("std");

const Vtu = @import("types.zig");

const UnstructuredMeshBuilder = @This();

const Point = [Vtu.UnstructuredMesh.DIMENSION]f64;

allocator: std.mem.Allocator,
points: std.ArrayList(f64),
connectivity: std.ArrayList(Vtu.IndexType),
connectivity_offsets: std.ArrayList(Vtu.IndexType),
cell_types: std.ArrayList(Vtu.CellType),

pub fn init(allocator: std.mem.Allocator) UnstructuredMeshBuilder {
    return .{
        .allocator = allocator,
        .points = std.ArrayList(f64).initCapacity(allocator, 0) catch unreachable,
        .connectivity = std.ArrayList(Vtu.IndexType).initCapacity(allocator, 0) catch unreachable,
        .connectivity_offsets = std.ArrayList(Vtu.IndexType).initCapacity(allocator, 0) catch unreachable,
        .cell_types = std.ArrayList(Vtu.CellType).initCapacity(allocator, 0) catch unreachable,
    };
}

pub fn deinit(self: *UnstructuredMeshBuilder) void {
    self.points.deinit(self.allocator);
    self.connectivity.deinit(self.allocator);
    self.connectivity_offsets.deinit(self.allocator);
    self.cell_types.deinit(self.allocator);
}

pub fn reservePoints(self: *UnstructuredMeshBuilder, num_points: usize) !void {
    const add_capacity = (num_points * Vtu.UnstructuredMesh.DIMENSION);
    try self.points.ensureTotalCapacity(self.allocator, self.points.items.len + add_capacity);
}

pub fn reserveCells(
    self: *UnstructuredMeshBuilder,
    cell_type: Vtu.CellType,
    num_cells: usize,
) !void {
    const add_capacity = (num_cells * Vtu.numCellPoints(cell_type));
    try self.connectivity.ensureTotalCapacity(self.allocator, self.connectivity.items.len + add_capacity);
    try self.connectivity_offsets.ensureTotalCapacity(self.allocator, self.connectivity_offsets.items.len + num_cells);
    try self.cell_types.ensureTotalCapacity(self.allocator, self.cell_types.items.len + num_cells);
}

pub fn addPoint(self: *UnstructuredMeshBuilder, point: Point) !Vtu.IndexType {
    const point_idx = self.points.items.len / Vtu.UnstructuredMesh.DIMENSION;
    try self.points.appendSlice(self.allocator, &point);
    return @intCast(point_idx);
}

pub fn addCell(
    self: *UnstructuredMeshBuilder,
    comptime cell_type: Vtu.CellType,
    point_idxs: [Vtu.numCellPoints(cell_type)]Vtu.IndexType,
) !void {
    try self.connectivity.appendSlice(self.allocator, &point_idxs);
    try self.connectivity_offsets.append(self.allocator, @intCast(self.connectivity.items.len));
    try self.cell_types.append(self.allocator, cell_type);
}

pub fn getUnstructuredMesh(self: *const UnstructuredMeshBuilder) Vtu.UnstructuredMesh {
    return .{
        .points = self.points.items,
        .connectivity = self.connectivity.items,
        .offsets = self.connectivity_offsets.items,
        .types = self.cell_types.items,
    };
}
