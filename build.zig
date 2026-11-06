// Modified by h0rv for Zig 0.17.0 and the standalone mcp.zig package.
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const mcp = b.addModule("mcp", .{
        .root_source_file = b.path("src/mcp.zig"),
        .target = target,
        .optimize = optimize,
    });
    const fixture = b.addExecutable(.{
        .name = "stdio_server",
        .root_module = b.createModule(.{
            .root_source_file = b.path("examples/stdio_server.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{.{ .name = "mcp", .module = mcp }},
        }),
    });
    const content_fixture = b.addExecutable(.{
        .name = "content_fixture",
        .root_module = b.createModule(.{
            .root_source_file = b.path("tests/fixture.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{.{ .name = "mcp", .module = mcp }},
        }),
    });
    const fixtures = b.addOptions();
    fixtures.addOptionPath("content_server", content_fixture.getEmittedBin());
    const client_tests = b.addTest(.{ .root_module = b.createModule(.{
        .root_source_file = b.path("tests/client.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{.{ .name = "mcp", .module = mcp }},
    }) });
    client_tests.root_module.addOptions("fixtures", fixtures);
    const run_client = b.addRunArtifact(client_tests);
    b.step("test-client", "Run the synthetic stdio content and ownership gate").dependOn(&run_client.step);
    const tests = b.addTest(.{ .root_module = mcp });
    const run = b.addRunArtifact(tests);
    run.setCwd(b.path("."));
    // SDK tests locate zig-out/bin/stdio_server relative to the package root.
    const install_fixture = b.addInstallArtifact(fixture, .{});
    run.step.dependOn(&install_fixture.step);
    b.step("test-sdk", "Run the SDK tests").dependOn(&run.step);
    const check = b.step("check", "Compile the upstream library tests and stdio fixture");
    check.dependOn(&tests.step);
    check.dependOn(&fixture.step);
    check.dependOn(&client_tests.step);
    const test_step = b.step("test", "Run upstream library tests and the local content gate");
    test_step.dependOn(&run.step);
    // The two suites share the SDK but no fixture state.
    test_step.dependOn(&run_client.step);
    b.default_step.dependOn(&tests.step);
    const fmt = b.addFmt(.{ .paths = &.{ b.path("build.zig"), b.path("build.zig.zon"), b.path("src"), b.path("examples"), b.path("tests") }, .check = true });
    b.step("fmt", "Check formatting").dependOn(&fmt.step);
}
