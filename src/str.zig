// imports
const std = @import("std");

// alias
const mem = std.mem;

pub fn strcmp(a: []u8, b: []u8) bool {
    return mem.eql(u8, a, b);
}