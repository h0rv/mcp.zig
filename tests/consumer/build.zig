const std = @import("std");
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const mcp = b.dependency("mcp", .{ .target = target, .optimize = optimize }).module("mcp");
    const exe = b.addExecutable(.{ .name = "mcp-consumer", .root_module = b.createModule(.{
        .root_source_file = b.path("main.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{.{ .name = "mcp", .module = mcp }},
    }) });
    b.installArtifact(exe);
    b.step("test", "Run the package consumer").dependOn(&b.addRunArtifact(exe).step);
}
