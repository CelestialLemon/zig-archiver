// imports
const std = @import("std");
const compress = @import("./compress.zig");
const file = @import("./file.zig");
const str = @import("./str.zig");
const utils = @import("./utils.zig");

// alias
const ArrayList = std.ArrayList;
const print = std.debug.print;
const Dir = std.fs.Dir;
const page_allocator = std.heap.page_allocator;
const mem = std.mem;

pub fn main() !void {
    // try app();

    const result = try compress.createCompressionData(@constCast("res"));
    const packedData = try compress.packCompressionData(result);

    for (result) | entry | {
        print("Entry [ path: {s}, hash: {s}, data.len: {d} ]\n", .{entry.path, entry.hash, entry.data.len});
    }

    const unpackedData = try compress.unpackCompressionData(packedData);

    for (unpackedData) | entry | {
        print("Entry [ path: {s}, hash: {s}, data.len: {d} ]\n", .{entry.path, entry.hash, entry.data.len});
    }
    // file.writeFile("res\\result.zar", packedData);

}

pub fn app() !void {
    const cli_args = try std.process.argsAlloc(page_allocator);

    const operation = cli_args[1];
    const input_file_path = cli_args[2];
    const output_file_path = cli_args[3];
    
    if (
        !str.strcmp(operation, @constCast("compress")) and
        !str.strcmp(operation, @constCast("decompress"))
        ) 
    {
        print("Incorrect arg 1", .{});
        return;   
    }

    const input_file_data = try file.readFile(input_file_path);

    var output_data: ?[]u8 = null;

    if (mem.eql(u8, operation, "compress")) {
        output_data = try compress.compressRawData(input_file_data);
    }
    else if (mem.eql(u8, operation, "decompress")) {
        output_data = try compress.decompressData(input_file_data);
    }
    else {
        return error.IncorrectArgs;
    }


    if (output_data) | data | {
        try file.writeFile(output_file_path, data);
    }

}
