const std = @import("std");
const csv = @import("csv.zig");
const markdown = @import("markdown.zig");

const usage = 
    \\csvmd - Convert CSV files to Markdown tables
    \\
    \\Usage: csvmd [options] <input.csv> [output.md]
    \\
    \\Options:
    \\  -h, --help     Show this help message
    \\  -v, --version  Show version information
    \\
    \\Arguments:
    \\  input.csv      Input CSV file (required)
    \\  output.md      Output Markdown file (optional, defaults to stdout)
    \\
    \\Examples:
    \\  csvmd data.csv            # Output to stdout
    \\  csvmd data.csv table.md   # Output to file
    \\
;

const version = "0.1.0";

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 2) {
        std.debug.print("{s}\n", .{usage});
        return;
    }

    // Parse command line arguments
    var input_file: ?[]const u8 = null;
    var output_file: ?[]const u8 = null;
    
    var i: usize = 1;
    while (i < args.len) {
        const arg = args[i];
        
        if (std.mem.eql(u8, arg, "-h") or std.mem.eql(u8, arg, "--help")) {
            std.debug.print("{s}\n", .{usage});
            return;
        } else if (std.mem.eql(u8, arg, "-v") or std.mem.eql(u8, arg, "--version")) {
            std.debug.print("csvmd version {s}\n", .{version});
            return;
        } else if (input_file == null) {
            input_file = arg;
        } else if (output_file == null) {
            output_file = arg;
        } else {
            std.debug.print("Error: Too many arguments\n\n{s}\n", .{usage});
            return;
        }
        
        i += 1;
    }

    if (input_file == null) {
        std.debug.print("Error: No input file specified\n\n{s}\n", .{usage});
        return;
    }

    // Process the CSV file
    processCSV(allocator, input_file.?, output_file) catch |err| {
        switch (err) {
            error.FileNotFound => std.debug.print("Error: Input file '{s}' not found\n", .{input_file.?}),
            error.AccessDenied => std.debug.print("Error: Permission denied accessing file '{s}'\n", .{input_file.?}),
            error.OutOfMemory => std.debug.print("Error: Out of memory\n", .{}),
            else => std.debug.print("Error: Failed to process CSV file: {}\n", .{err}),
        }
    };
}

fn processCSV(allocator: std.mem.Allocator, input_path: []const u8, output_path: ?[]const u8) !void {
    // Read the CSV file
    const csv_data = try csv.parseFile(allocator, input_path);
    defer csv.freeCsvData(allocator, csv_data);

    // Convert to Markdown
    const markdown_output = try markdown.generateTable(allocator, csv_data);
    defer allocator.free(markdown_output);

    // Write output
    if (output_path) |path| {
        const file = try std.fs.cwd().createFile(path, .{});
        defer file.close();
        try file.writeAll(markdown_output);
        std.debug.print("Markdown table written to '{s}'\n", .{path});
    } else {
        std.debug.print("{s}", .{markdown_output});
    }
}

test "main tests" {
    // Basic test to ensure main compiles
    const testing = std.testing;
    _ = testing;
}