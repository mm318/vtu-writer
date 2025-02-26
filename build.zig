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

    // Creates a step for building a shared library
    const lib = b.addStaticLibrary(.{
        .name = "vtu_writer",
        .root_source_file = b.path("src/lib.zig"),
        .target = target,
        .optimize = optimize,
    });
    const zlib_dep = b.dependency("zlib", .{
        .target = target,
        .optimize = optimize,
    });
    lib.root_module.addIncludePath(zlib_dep.artifact("z").getEmittedIncludeTree());
    lib.linkLibrary(zlib_dep.artifact("z"));

    // This declares intent for the shared library to be installed into the
    // standard location when the user invokes the "install" step (the default
    // step when running `zig build`).
    b.installArtifact(lib);

    // Creates a step for demoing. This only builds the demo test executable
    // but does not run it.
    const demo = b.addExecutable(.{
        .name = "vtu_writer_demo",
        .root_source_file = b.path("tests/demo.zig"),
        .target = target,
        .optimize = optimize,
    });
    demo.root_module.addImport("vtu_writer", &lib.root_module);

    const run_demo = b.addRunArtifact(demo);
    const demo_cmdline_target = b.step("run", "Run the demo test");
    demo_cmdline_target.dependOn(&run_demo.step);

    // Creates a step for unit testing. This only builds the test executable
    // but does not run it.
    const tests = b.addTest(.{
        .root_source_file = b.path("tests/test.zig"),
        .target = target,
        .optimize = optimize,
    });
    tests.root_module.addImport("vtu_writer", &lib.root_module);

    const run_unit_tests = b.addRunArtifact(tests);
    run_unit_tests.has_side_effects = true;

    // This exposes a `test` step to the `zig build --help` menu
    // providing a way for the user to request running the unit tests.
    const test_cmdline_target = b.step("test", "Run the comprehensive tests");
    test_cmdline_target.dependOn(&run_unit_tests.step);
}
