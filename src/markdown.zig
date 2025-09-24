const std = @import("std");
const csv = @import("csv.zig");

pub fn generateTable(allocator: std.mem.Allocator, csv_data: csv.CsvData) ![]u8 {
    if (csv_data.rows.len == 0) {
        return try allocator.dupe(u8, "");
    }

    var result = std.ArrayList(u8).init(allocator);
    defer result.deinit();

    // Add the header row
    if (csv_data.rows.len > 0) {
        try result.appendSlice("| ");
        try result.appendSlice(csv_data.rows[0]);
        try result.appendSlice(" |\n");

        // Add separator row
        const header_cols = countColumns(csv_data.rows[0]);
        try result.appendSlice("|");
        for (0..header_cols) |_| {
            try result.appendSlice(" --- |");
        }
        try result.appendSlice("\n");
    }

    // Add data rows
    for (csv_data.rows[1..]) |row| {
        try result.appendSlice("| ");
        try result.appendSlice(row);
        try result.appendSlice(" |\n");
    }

    return try result.toOwnedSlice();
}

fn countColumns(row: []const u8) usize {
    var count: usize = 1;
    var i: usize = 0;
    
    while (i < row.len) {
        if (row[i] == '|') {
            count += 1;
        }
        i += 1;
    }
    
    return count;
}

pub fn escapeMarkdown(allocator: std.mem.Allocator, text: []const u8) ![]u8 {
    var result = std.ArrayList(u8).init(allocator);
    defer result.deinit();

    for (text) |char| {
        switch (char) {
            '|' => try result.appendSlice("\\|"),
            '\\' => try result.appendSlice("\\\\"),
            else => try result.append(char),
        }
    }

    return try result.toOwnedSlice();
}

test "generate simple markdown table" {
    const testing = std.testing;
    const allocator = testing.allocator;

    // Create test CSV data
    const rows = try allocator.alloc([]const u8, 3);
    defer allocator.free(rows);
    
    rows[0] = try allocator.dupe(u8, "Name | Age | City");
    rows[1] = try allocator.dupe(u8, "John | 25 | New York");
    rows[2] = try allocator.dupe(u8, "Jane | 30 | Los Angeles");
    
    const csv_data = csv.CsvData{ .rows = rows };

    const markdown = try generateTable(allocator, csv_data);
    defer allocator.free(markdown);

    const expected = 
        \\| Name | Age | City |
        \\| --- | --- | --- |
        \\| John | 25 | New York |
        \\| Jane | 30 | Los Angeles |
        \\
    ;

    try testing.expectEqualStrings(expected, markdown);

    // Clean up
    for (rows) |row| {
        allocator.free(row);
    }
}

test "escape markdown characters" {
    const testing = std.testing;
    const allocator = testing.allocator;

    const input = "Text with | pipe and \\ backslash";
    const escaped = try escapeMarkdown(allocator, input);
    defer allocator.free(escaped);

    try testing.expectEqualStrings("Text with \\| pipe and \\\\ backslash", escaped);
}