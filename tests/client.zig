const std = @import("std");
const mcp = @import("mcp");
const fixture = @import("fixtures").content_server;

fn call(client: *mcp.Client, arena: std.mem.Allocator, sequence: i64) !mcp.CallToolResult {
    return client.callTool(arena, "mixed", .{ .sequence = sequence }, .{ .timeout = .fromSeconds(5), .retry = .never });
}

fn expectBinary(encoded: []const u8) !void {
    var decoded: [4]u8 = undefined;
    try std.base64.standard.Decoder.decode(&decoded, encoded);
    try std.testing.expectEqualSlices(u8, &.{ 0, 1, 2, 255 }, &decoded);
}

test "spawn, discover and concurrent correlated results own all content after client teardown" {
    const io = std.testing.io;
    const gpa = std.testing.allocator;
    var first_arena = std.heap.ArenaAllocator.init(gpa);
    defer first_arena.deinit();
    var second_arena = std.heap.ArenaAllocator.init(gpa);
    defer second_arena.deinit();
    const a = first_arena.allocator();
    const b = second_arena.allocator();
    var first_result: mcp.CallToolResult = undefined;
    var second_result: mcp.CallToolResult = undefined;
    var read_result: mcp.ReadResourceResult = undefined;
    {
        const proc = try mcp.transport.stdio.Client.spawn(io, gpa, .{ .argv = &.{fixture} });
        defer proc.deinit();
        var client = mcp.Client.init(gpa, io, .{ .info = .{ .name = "content-gate", .version = "1" } });
        defer client.deinit();
        client.connect(proc.transport());
        const discovery = try client.discover(a, .{ .timeout = .fromSeconds(5) });
        try std.testing.expectEqualStrings("2026-07-28", discovery.supportedVersions[0]);
        const tools = try client.listTools(a, null, .{});
        try std.testing.expectEqualStrings("mixed", tools.tools[0].name);
        var first = try io.concurrent(call, .{ &client, a, @as(i64, 1) });
        defer _ = first.cancel(io) catch {};
        var second = try io.concurrent(call, .{ &client, b, @as(i64, 2) });
        defer _ = second.cancel(io) catch {};
        second_result = try second.await(io);
        first_result = try first.await(io);
        read_result = try client.readResource(a, "fixture://blob", .{});
    }
    // Both the transport and the client's scratch allocations have been released.
    try std.testing.expectEqualStrings("sequence-1", first_result.content[0].text.text);
    try std.testing.expectEqualStrings("sequence-2", second_result.content[0].text.text);
    try std.testing.expectEqual(@as(i64, 1), first_result.structuredContent.?.object.get("sequence").?.integer);
    try std.testing.expectEqual(@as(i64, 2), second_result.structuredContent.?.object.get("sequence").?.integer);
    for ([_]mcp.CallToolResult{ first_result, second_result }) |result| {
        try std.testing.expectEqual(@as(usize, 5), result.content.len);
        try std.testing.expectEqualStrings("image/png", result.content[1].image.mimeType);
        try expectBinary(result.content[1].image.data);
        try std.testing.expectEqualStrings("audio/wav", result.content[2].audio.mimeType);
        try expectBinary(result.content[2].audio.data);
        try std.testing.expectEqualStrings("application/octet-stream", result.content[3].resource.resource.blob.mimeType.?);
        try expectBinary(result.content[3].resource.resource.blob.blob);
        try std.testing.expectEqualStrings("fixture://blob", result.content[4].resource_link.uri);
    }
    try std.testing.expectEqualStrings("{\"fixture\":true}", read_result.contents[0].text.text);
    try expectBinary(read_result.contents[1].blob.blob);
}
