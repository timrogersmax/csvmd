const std = @import("std");

pub const CsvData = struct {
    rows: [][]const u8,
    
    const Self = @This();
    
    pub fn deinit(self: Self, allocator: std.mem.Allocator) void {
        for (self.rows) |row| {
            allocator.free(row);
        }
        allocator.free(self.rows);
    }
};

pub fn parseFile(allocator: std.mem.Allocator, file_path: []const u8) !CsvData {
    const file = try std.fs.cwd().openFile(file_path, .{});
    defer file.close();

    const file_size = try file.getEndPos();
    const contents = try allocator.alloc(u8, file_size);
    defer allocator.free(contents);
    
    _ = try file.readAll(contents);
    
    return parseString(allocator, contents);
}

pub fn parseString(allocator: std.mem.Allocator, csv_content: []const u8) !CsvData {
    var rows = std.ArrayList([]const u8).init(allocator);
    defer rows.deinit();

    var lines = std.mem.split(u8, csv_content, "\n");
    while (lines.next()) |line| {
        // Skip empty lines
        const trimmed_line = std.mem.trim(u8, line, " \t\r");
        if (trimmed_line.len == 0) continue;

        const parsed_row = try parseRow(allocator, trimmed_line);
        try rows.append(parsed_row);
    }

    return CsvData{
        .rows = try rows.toOwnedSlice(),
    };
}

fn parseRow(allocator: std.mem.Allocator, row_content: []const u8) ![]const u8 {
    var fields = std.ArrayList([]const u8).init(allocator);
    defer fields.deinit();

    var i: usize = 0;
    var start: usize = 0;
    var in_quotes = false;

    while (i <= row_content.len) {
        const char = if (i < row_content.len) row_content[i] else 0;

        if (char == '"') {
            in_quotes = !in_quotes;
        } else if ((char == ',' or char == 0) and !in_quotes) {
            // Extract field
            var field_end = i;
            var field_start = start;
            
            // Handle quoted fields
            if (field_start < row_content.len and row_content[field_start] == '"') {
                field_start += 1;
                if (field_end > 0 and row_content[field_end - 1] == '"') {
                    field_end -= 1;
                }
            }

            const field = std.mem.trim(u8, row_content[field_start..field_end], " \t");
            const owned_field = try allocator.dupe(u8, field);
            try fields.append(owned_field);
            
            start = i + 1;
        }

        if (char == 0) break;
        i += 1;
    }

    // Join fields with pipe separator for markdown
    var result = std.ArrayList(u8).init(allocator);
    defer result.deinit();

    for (fields.items, 0..) |field, idx| {
        if (idx > 0) {
            try result.appendSlice(" | ");
        }
        try result.appendSlice(field);
        allocator.free(field); // Free the individual field
    }

    return try result.toOwnedSlice();
}

pub fn freeCsvData(allocator: std.mem.Allocator, csv_data: CsvData) void {
    csv_data.deinit(allocator);
}

test "parse simple CSV" {
    const testing = std.testing;
    const allocator = testing.allocator;

    const csv_content = "Name,Age,City\nJohn,25,New York\nJane,30,Los Angeles";
    const csv_data = try parseString(allocator, csv_content);
    defer freeCsvData(allocator, csv_data);

    try testing.expect(csv_data.rows.len == 3);
    try testing.expectEqualStrings(csv_data.rows[0], "Name | Age | City");
    try testing.expectEqualStrings(csv_data.rows[1], "John | 25 | New York");
    try testing.expectEqualStrings(csv_data.rows[2], "Jane | 30 | Los Angeles");
}

test "parse CSV with quotes" {
    const testing = std.testing;
    const allocator = testing.allocator;

    const csv_content = "\"Name\",\"Age with, comma\",\"City\"\n\"John Doe\",\"25, years\",\"New York\"";
    const csv_data = try parseString(allocator, csv_content);
    defer freeCsvData(allocator, csv_data);

    try testing.expect(csv_data.rows.len == 2);
    try testing.expectEqualStrings(csv_data.rows[0], "Name | Age with, comma | City");
    try testing.expectEqualStrings(csv_data.rows[1], "John Doe | 25, years | New York");
}