// imports
const std = @import("std");
// aliases
const page_allocator = std.heap.page_allocator;
const print = std.debug.print;

pub fn intToBytes(comptime T: type, val: T) ![]u8 {

    var n = val;
    const size = @sizeOf(T) / @sizeOf(u8);
    var i: usize = 0;
    
    const bytes: []u8 = try page_allocator.alloc(u8, size);
    
    while (i < size) : (i += 1) {
        const digit: u8 = @intCast(n % 256);
        bytes[i] = digit;
        n /= 256;
    }

    return bytes;
}

pub fn bytesToInt(comptime T: type, bytes: []u8) !T {
    var sum: T = 0;
    for (0..bytes.len) | i | {
        sum += bytes[i] * std.math.pow(T, 256, @intCast(i));
    }
    return sum;
}

pub fn readNBytes(reader: anytype, num_of_bytes: usize) ![]u8 {
    const buffer = try page_allocator.alloc(u8, num_of_bytes);

    var i: usize = 0;
    while (i < num_of_bytes) : (i += 1) {
        buffer[i] = try reader.readByte();
    }

    return buffer;
}