// imports
const std = @import("std");
const file = @import("./file.zig");
const utils = @import("./utils.zig");
const str = @import("./str.zig");

// alias
const print = std.debug.print;
const ArrayList = std.ArrayList;
const page_allocator = std.heap.page_allocator;
const fs = std.fs;
const Dir = std.fs.Dir;
const mem = std.mem;

// data types
pub const FileCompressionData = struct {
    // relative path to the file
    path: []u8,
    // hash of the file contents
    hash: []u8,
    // compressed data of the file
    data: []u8
};

pub fn compressRawData(input: []u8) ![]u8 {
    // create readable stream from input buffer
    var input_stream = std.io.fixedBufferStream(input);
    // create writable stream for output
    var output = ArrayList(u8).init(page_allocator);
    defer output.deinit();

    // run compress
    try std.compress.zlib.compress(
        input_stream.reader(), 
        output.writer(), 
        .{ .level = std.compress.flate.deflate.Level.default 
    });

    // return result
    return output.toOwnedSlice();
}

pub fn decompressData(input: []u8) ![]u8 {
    // create readable stream from input buffer
    var input_stream = std.io.fixedBufferStream(input);
    // create writable stream for output
    var output = ArrayList(u8).init(page_allocator);
    defer output.deinit();

    // run decompress
    try std.compress.zlib.decompress(input_stream.reader(), output.writer());

    // return result
    return output.toOwnedSlice();
}

// takes a directory path and creates compression data for all files in it
// it includes files present in sub-directories
pub fn createDirCompressionData(path: []u8) ![]FileCompressionData {
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
        // we can only work with file kinds
        if (entry.kind != Dir.Entry.Kind.file) {
            return error.UnknownEntryType;
        }

        print("Processing file: {s}\n", .{ entry.path });

        // create the file path by concating the path with entry path ("<path>\<entry.path>")
        const filepath = try str.strcat(&[_][]u8{ 
            path, 
            @constCast("\\"), 
            @constCast(entry.path) 
        });

        // read data from the file and compress it
        const file_input_data = try file.readFile(filepath);
        const compressed_data = try compressRawData(file_input_data);

        // create new data object and allocate required memory for the properties
        const compression_data = FileCompressionData {
            .path = try page_allocator.alloc(u8, filepath.len),
            .hash = "",
            .data = try page_allocator.alloc(u8, compressed_data.len)
        };

        // copy data into the object's properties
        mem.copyForwards(u8, compression_data.path, filepath);
        mem.copyForwards(u8, compression_data.data, compressed_data);
        
        // add the object to list
        try result.append(compression_data);
    }

    // create slice from list and return
    // list will be emptied by this function
    return result.toOwnedSlice();
}

pub fn createFileCompressionData(filepath: []u8) ![]FileCompressionData {
    // read the data and compress it
    const file_data = try file.readFile(filepath);
    const compressed_data = try compressRawData((file_data));

    // create entry
    const compression_data = FileCompressionData {
        .path = try page_allocator.alloc(u8, filepath.len),
        .hash = "",
        .data = try page_allocator.alloc(u8, compressed_data.len)
    };

    // copy data into the object's properties
    mem.copyForwards(u8, compression_data.path, filepath);
    mem.copyForwards(u8, compression_data.data, compressed_data);

    // create list and append the entry
    var list = ArrayList(FileCompressionData).init(page_allocator);
    defer list.deinit();

    try list.append(compression_data);

    // return slice
    return list.toOwnedSlice();
}

// creates a packed u8 buffer from the given compression data
pub fn packCompressionData(data: []FileCompressionData) ![]u8 {
    // create a list so we can use a writer
    var result = ArrayList(u8).init(page_allocator);
    defer result.deinit();
    const writer = result.writer();

    // write the length of the data array first as bytes
    _ = try writer.write(try utils.intToBytes(usize, data.len));

    // loop through entries in data
    for (data) | entry | {
        // for every entry write the length of the property then the property itself
        _ = try writer.write(try utils.intToBytes(usize, entry.path.len));
        _ = try writer.write(entry.path); 
        _ = try writer.write(try utils.intToBytes(usize, entry.hash.len));
        _ = try writer.write(entry.hash); 
        _ = try writer.write(try utils.intToBytes(usize, entry.data.len));
        _ = try writer.write(entry.data); 
    }

    return result.toOwnedSlice();
}

pub fn unpackCompressionData(buffer: []u8) ![]FileCompressionData {
    // create outuput list
    var result = ArrayList(FileCompressionData).init(page_allocator);
    defer result.deinit();

    // create a readable stream so we can use a reader
    var input_stream = std.io.fixedBufferStream(buffer);
    var reader = input_stream.reader();

    // read first 8 bytes of the buffer which represent the number of entries 
    const n_entries = try utils.bytesToInt(usize, try utils.readNBytes(&reader, 8));
    
    // loop n_entries times
    for (0..n_entries) | _ | {
        // for each property we store its length first so read that as a usize
        // then read the property itself by reading the length num of bytes

        const path_len = try utils.bytesToInt(usize, try utils.readNBytes(&reader, 8));
        const path = try utils.readNBytes(&reader, path_len);

        const hash_len = try utils.bytesToInt(usize, try utils.readNBytes(&reader, 8));
        const hash = try utils.readNBytes(&reader, hash_len);

        const data_len = try utils.bytesToInt(usize, try utils.readNBytes(&reader, 8));
        const data = try utils.readNBytes(&reader, data_len);

        // initialize compression data object with required buffers
        const compression_data = FileCompressionData {
            .path = try page_allocator.alloc(u8, path_len),
            .hash = try page_allocator.alloc(u8, hash_len),
            .data = try page_allocator.alloc(u8, data_len)
        };

        // copy the data unpacked into the object
        mem.copyForwards(u8, compression_data.path, path);
        mem.copyForwards(u8, compression_data.hash, hash);
        mem.copyForwards(u8, compression_data.data, data);

        // add object to list
        try result.append(compression_data);
    }

    // return resulting slice
    return result.toOwnedSlice();
}
