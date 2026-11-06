// Local synthetic MCP fixture using the vendored SDK, with no external services.
const std = @import("std");
const mcp = @import("mcp");

const Args = struct { sequence: i64 };

fn mixed(ctx: *mcp.RequestContext, args: Args) anyerror!mcp.Outcome(mcp.CallToolResult) {
    if (args.sequence == 1) try ctx.io.sleep(.fromMilliseconds(30), .awake);
    const content = try ctx.arena.alloc(mcp.types.ContentBlock, 5);
    content[0] = .{ .text = .{ .text = try ctx.arena.print("sequence-{d}", .{args.sequence}) } };
    content[1] = .{ .image = .{ .data = "AAEC/w==", .mimeType = "image/png" } };
    content[2] = .{ .audio = .{ .data = "AAEC/w==", .mimeType = "audio/wav" } };
    content[3] = .{ .resource = .{ .resource = .{ .blob = .{ .uri = "fixture://blob", .mimeType = "application/octet-stream", .blob = "AAEC/w==" } } } };
    content[4] = .{ .resource_link = .{ .name = "blob", .uri = "fixture://blob", .mimeType = "application/octet-stream" } };
    var object: std.json.ObjectMap = .empty;
    try object.put(ctx.arena, "sequence", .{ .integer = args.sequence });
    return .{ .complete = .{ .content = content, .structuredContent = .{ .object = object } } };
}

fn resource(ctx: *mcp.RequestContext, uri: []const u8) anyerror!mcp.Outcome(mcp.ReadResourceResult) {
    const contents = try ctx.arena.alloc(mcp.types.ResourceContents, 2);
    contents[0] = .{ .text = .{ .uri = uri, .mimeType = "application/json", .text = "{\"fixture\":true}" } };
    contents[1] = .{ .blob = .{ .uri = uri, .mimeType = "application/octet-stream", .blob = "AAEC/w==" } };
    return .{ .complete = .{ .contents = contents } };
}

pub fn main(init: std.process.Init) !void {
    var server = try mcp.Server.init(init.gpa, init.io, .{ .info = .{ .name = "local-fixture", .version = "1" } });
    defer server.deinit();
    try server.addTool(.{ .name = "mixed" }, mixed);
    try server.addResource(.{ .uri = "fixture://blob", .name = "blob" }, resource);
    try mcp.transport.stdio.serve(init.io, init.gpa, &server);
}
