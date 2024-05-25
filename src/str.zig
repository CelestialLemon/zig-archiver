// imports
const std = @import("std");

// alias
const mem = std.mem;
const page_allocator = std.heap.page_allocator;

pub fn strcmp(a: []u8, b: []u8) bool {
    return mem.eql(u8, a, b);
}

pub fn strcat(segments: []const []u8) ![]u8 {
    return mem.concat(page_allocator, u8, segments);
}
