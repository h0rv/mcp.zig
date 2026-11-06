# mcp.zig

An MCP client and server library for Zig. It supports stdio and HTTP with SSE. No external HTTP or TLS library is required.

The supported MCP protocol revision is `2026-07-28`. Older revisions and gRPC are not supported.

## Build and test

Use Zig 0.17.0.

```sh
zig build check -j2
zig build test -j2 --summary all
zig build test -Doptimize=ReleaseSafe -j2 --summary all
zig build fmt
```

`test` runs the SDK and client suites with local fixtures. Use `test-sdk` or `test-client` to run one suite.

The stdio example is built at `zig-out/bin/stdio_server` during `test-sdk` or `test`.

## Use as a dependency

Add the repository at your chosen revision with `zig fetch --save=mcp <package-url>`. Import the module in your build:

```zig
const mcp = b.dependency("mcp", .{
    .target = target,
    .optimize = optimize,
}).module("mcp");
exe.root_module.addImport("mcp", mcp);
```

A minimal stdio server uses the public API:

```zig
const std = @import("std");
const mcp = @import("mcp");

pub fn main(init: std.process.Init) !void {
    var server = try mcp.Server.init(init.gpa, init.io, .{
        .info = .{ .name = "example", .version = "1" },
    });
    defer server.deinit();
    try mcp.transport.stdio.serve(init.io, init.gpa, &server);
}
```

See `examples/stdio_server.zig` for tool, resource and prompt registration. To check package imports from a separate build, run `zig build test -j2` in `tests/consumer`.

## License

The SDK remains under Apache License 2.0. `LICENSE`, `NOTICE` and `THIRD_PARTY_LICENSES.md` retain the upstream notices. Test fixtures include their own licenses and source records.
