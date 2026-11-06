const std = @import("std");
const mcp = @import("mcp");
pub fn main(init: std.process.Init) void {
    var client = mcp.Client.init(init.gpa, init.io, .{ .info = .{ .name = "consumer", .version = "1" } });
    defer client.deinit();
    std.debug.assert(client.transport == null);
    _ = &mcp.transport.stdio.Client.spawn;
}
