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
    try app();
}

pub fn app() !void {
    const cli_args = try std.process.argsAlloc(page_allocator);

    const operation = cli_args[1];
    const entry_type = cli_args[2];
    const input_path = cli_args[3];
    const output_path = cli_args[4];
    
    if (
        !str.strcmp(operation, @constCast("compress")) and
        !str.strcmp(operation, @constCast("decompress"))
        ) 
    {
        print("Incorrect arg 1", .{});
        return;   
    }

    if (str.strcmp(operation, @constCast("compress"))) {
        var compression_data: ?[]compress.FileCompressionData = null;
        if (str.strcmp(entry_type, @constCast("file"))) {
            compression_data = try compress.createFileCompressionData(input_path);
        }
        else if (str.strcmp(entry_type, @constCast("dir"))) {
            compression_data = try compress.createDirCompressionData(input_path);
        }
        else {
            return error.IncorrectArgs;
        }

        if (compression_data) | data | {
            const packed_data = try compress.packCompressionData(data);
            try file.writeFile(output_path, packed_data);
        }

    }
    else if (str.strcmp(operation, @constCast("decompress"))) {
        const file_data = try file.readFile(input_path);
        const unpacked_data = try compress.unpackCompressionData(file_data);

        for (unpacked_data) | entry | {
            const dir_path = file.getFileDirPath(entry.path);

            if (dir_path.len > 0) {
                try std.fs.cwd().makePath(dir_path);
            }

            const decompressed_data = try compress.decompressData(entry.data);
            try file.writeFile(entry.path, decompressed_data);
        }
    }
    else {
        return error.IncorrectArgs;
    }

}
