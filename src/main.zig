const std = @import("std");
const ArrayList = std.ArrayList;
const print = std.debug.print;
const page_allocator = std.heap.page_allocator;

fn decompress_and_print(input: []u8) !void {
    var input_stream = std.io.fixedBufferStream(input);

    var output = ArrayList(u8).init(page_allocator);
    defer output.deinit();

    try std.compress.flate.decompress(input_stream.reader(), output.writer());
}

fn compress_data(input: []u8) ![]u8 {
    var input_stream = std.io.fixedBufferStream(input);

    var output = ArrayList(u8).init(page_allocator);

    try std.compress.zlib.compress(input_stream.reader(), output.writer(), .{ .level = std.compress.flate.deflate.Level.default });

    return output.items;
}

pub fn main() !void {
    // const data = "Hello world this is our input string\n";
    // var output = ArrayList(u8).init(std.heap.page_allocator);
    // defer output.deinit();

    // var input_stream = std.io.fixedBufferStream(data);

    // try std.compress.zlib.compress(input_stream.reader(), output.writer(), .{ .level = std.compress.flate.deflate.Level.fast });

    // print("Result: {s}\n", .{output.items});

    const input_file_handle = try std.fs.cwd().openFile("res/test.txt", .{});
    const file_size = (try input_file_handle.stat()).size;

    const buffer = try page_allocator.alloc(u8, file_size);
    _ = try input_file_handle.read(buffer);

    var output = ArrayList(u8).init(page_allocator);
    defer output.deinit();

    var input_stream = std.io.fixedBufferStream(buffer);

    try std.compress.flate.compress(input_stream.reader(), output.writer(), .{ .level = std.compress.flate.deflate.Level.best });

    try decompress_and_print(output.items);
}
