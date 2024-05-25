// imports
const std = @import("std");
const file = @import("./file.zig");

// alias
const print = std.debug.print;
const ArrayList = std.ArrayList;
const page_allocator = std.heap.page_allocator;
const fs = std.fs;
const Dir = std.fs.Dir;
const mem = std.mem;

// data types
const FileCompressionData = struct {
    path: []u8,
    hash: []u8,
    data: []u8
};

pub fn compressRawData(input: []u8) ![]u8 {
    var input_stream = std.io.fixedBufferStream(input);
    var output = ArrayList(u8).init(page_allocator);

    try std.compress.zlib.compress(
        input_stream.reader(), 
        output.writer(), 
        .{ .level = std.compress.flate.deflate.Level.default 
    });

    return output.items;
}

pub fn decompress_data(input: []u8) ![]u8 {
    var input_stream = std.io.fixedBufferStream(input);
    var output = ArrayList(u8).init(page_allocator);

    try std.compress.zlib.decompress(input_stream.reader(), output.writer());

    return output.items;
}

pub fn createCompressionData(path: []u8) ![]FileCompressionData {
    // create a list to store result
    var result = ArrayList(FileCompressionData).init(page_allocator);
    defer result.deinit(); 

    // open directory to read its contents
    var dir = try fs.cwd().openDir(path, .{ .iterate = true });
    defer dir.close();

    // init a walker for the dir
    var walker = try dir.walk(page_allocator);
    defer walker.deinit();


    // walk the dir
    while (try walker.next()) | entry | {
        // we don't need to process dir entries
        if (entry.kind == Dir.Entry.Kind.directory) {
            continue;
        }
        // we can only work with file and dir kinds
        if (entry.kind != Dir.Entry.Kind.file) {
            return error.UnknownEntryType;
        }

        print("Processing file: {s}\n", .{ entry.path });

        // read data from the file and compress it
        const file_input_data = try file.readFile(@constCast(entry.path));
        const compressed_data = try compressRawData(file_input_data);

        // create new data object and allocate required memory for the properties
        const compressionData = FileCompressionData {
            .path = try page_allocator.alloc(u8, entry.path.len),
            .hash = "",
            .data = try page_allocator.alloc(u8, compressed_data.len)
        };

        // copy data into the object's properties
        mem.copyForwards(u8, compressionData.path, entry.path);
        mem.copyForwards(u8, compressionData.data, compressed_data);
        
        // add the object to list
        try result.append(compressionData);
    }

    // create slice from list and return
    // list will be emptied by this function
    return result.toOwnedSlice();
}
