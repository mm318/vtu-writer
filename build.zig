const std = @import("std");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    const zlib_dep = b.dependency("zlib", .{
        .target = target,
        .optimize = optimize,
    });
    const zlib = zlib_dep.artifact("z");

    // Creates a step for building a shared library
    const vtu_writer = b.addModule("vtu_writer", .{
        .root_source_file = b.path("src/lib.zig"),
        .target = target,
        .optimize = optimize,
    });
    vtu_writer.addIncludePath(zlib.getEmittedIncludeTree());
    vtu_writer.linkLibrary(zlib);

    // Creates a step for demoing. This only builds the demo test executable
    // but does not run it.
    const demo = b.addExecutable(.{
        .name = "vtu_writer_demo",
        .root_module = b.createModule(.{
            .root_source_file = b.path("tests/demo.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    demo.root_module.addImport("vtu_writer", vtu_writer);

    const run_demo = b.addRunArtifact(demo);
    const demo_cmdline_target = b.step("run", "Run the demo test");
    demo_cmdline_target.dependOn(&run_demo.step);

    // Creates a step for unit testing. This only builds the test executable
    // but does not run it.
    const tests = b.addTest(.{
        .name = "vtu_writer_tests",
        .root_module = b.createModule(.{
            .root_source_file = b.path("tests/test.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    tests.root_module.addImport("vtu_writer", vtu_writer);

    const run_unit_tests = b.addRunArtifact(tests);
    run_unit_tests.has_side_effects = true;

    // This exposes a `test` step to the `zig build --help` menu
    // providing a way for the user to request running the unit tests.
    const test_cmdline_target = b.step("test", "Run the comprehensive tests");
    test_cmdline_target.dependOn(&run_unit_tests.step);
}
