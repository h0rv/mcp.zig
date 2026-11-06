# mcp.zig

mcp.zig is a Zig 0.17.0 fork of [ChristianPresley/zig-sdk](https://github.com/ChristianPresley/zig-sdk) v0.5.1. It contains the port first tested in Newt. See `NOTICE` for the origin and changes.

Use it to build MCP clients and servers over stdio or HTTP with SSE. The native HTTP and TLS implementations are retained. The only supported MCP protocol revision is `2026-07-28`. This fork does not support older protocol revisions or gRPC.

## Build and test

Use Zig 0.17.0.

```sh
zig build check -j2
zig build test -j2 --summary all
zig build test -Doptimize=ReleaseSafe -j2 --summary all
zig build fmt
```

`test` runs the SDK suite and a stdio client test for concurrent calls and result ownership. `test-sdk` and `test-client` run those suites separately. Tests use local fixtures and loopback connections. Test counts are not a claim of full protocol conformance.

The stdio example is built at `zig-out/bin/stdio_server` during `test-sdk` or `test`.

## Use as a dependency

Add the repository at your chosen revision with `zig fetch --save=mcp <package-url>`. Keep the dependency revision and hash in `build.zig.zon`, not application source. Import the module in your build:

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
