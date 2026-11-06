// Local Zig 0.17 compatibility helper. Repeats complete byte patterns without allocation.
pub fn bytes(comptime pattern: []const u8, comptime count: usize) [pattern.len * count:0]u8 {
    @setEvalBranchQuota(count * 4 + 1000);
    var result: [pattern.len * count:0]u8 = undefined;
    for (0..count) |i| @memcpy(result[i * pattern.len ..][0..pattern.len], pattern);
    result[pattern.len * count] = 0;
    return result;
}
