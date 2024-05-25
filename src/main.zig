// imports
const std = @import("std");
const compress = @import("./compress.zig");
const file = @import("./file.zig");
const str = @import("./str.zig");

// alias
const ArrayList = std.ArrayList;
const print = std.debug.print;
const Dir = std.fs.Dir;
const page_allocator = std.heap.page_allocator;
const mem = std.mem;

pub fn main() !void {
    // try app();

    const result = try compress.createCompressionData("");

    var i: u32 = 0;
    var totalSize: u64 = 0;
    while (i < result.len) : (i = i + 1) {
        const entry = result[i];
        totalSize = totalSize + entry.path.len + entry.hash.len + entry.data.len;
    }

    print("Total Size: {d}\n", .{ totalSize });
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
        output_data = try compress.compress_data(input_file_data);
    }
    else if (mem.eql(u8, operation, "decompress")) {
        output_data = try compress.decompress_data(input_file_data);
    }
    else {
        return error.IncorrectArgs;
    }


    if (output_data) | data | {
        try file.writeFile(output_file_path, data);
    }

}
