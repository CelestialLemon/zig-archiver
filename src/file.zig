// imports
const std = @import("std");
// alias
const fs = std.fs;
const page_allocator = std.heap.page_allocator;

// public functions
pub fn readFile(filepath: []u8) ![]u8 {
    const file_handle = try fs.cwd().openFile(filepath, .{});
    defer file_handle.close();

    const file_size = (try file_handle.stat()).size;

    const buffer = try page_allocator.alloc(u8, file_size);

    _ = try file_handle.read(buffer);

    return buffer;
}

pub fn writeFile(filepath: []u8, buffer: []u8) !void {
    const file_handle = try fs.cwd().createFile(filepath, .{});
    defer file_handle.close();

    _ = try file_handle.write(buffer);
}
