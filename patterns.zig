const std = @import("std");
const builtin = @import("builtin");
const expect = std.testing.expect;

test "allocation" {
    const allocator = std.heap.page_allocator;
    const memory = try allocator.alloc(u8, 100);
    defer allocator.free(memory);

    try expect(memory.len == 100);
    try expect(@TypeOf(memory) == []u8);
}

// test "fixed buffer allocator" {
//     var buffer: [1000]u8 = undefined;
//     var fba = std.heap.FixedBufferAllocator.init(&buffer);
//     var allocator = &fba.allocator;
//
//     const memory = try allocator.alloc(u8, 100);
//     defer allocator.free(memory);
//
//     try expect(memory.len == 100);
//     try expect(@TypeOf(memory) == []u8);
// }

// test "arena allocator" {
//     var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
//     defer arena.deinit();
//     var allocator = &arena.allocator;
//
//     _ = try allocator.alloc(u8, 1);
//     _ = try allocator.alloc(u8, 10);
//     _ = try allocator.alloc(u8, 100);
// }

// alloc and free are used for slices. For single items, consider using create and destroy.
test "allocator create/destroy" {
    const byte = try std.heap.page_allocator.create(u8);
    defer std.heap.page_allocator.destroy(byte);
    byte.* = 128;
}

// test "GPA" {
//     var gpa = std.heap.GeneralPurposeAllocator(.{}){};
//     defer {
//         const leaked = gpa.deinit();
//         if (leaked) expect(false) catch @panic("TEST FAIL"); // fail test
//     }
//     const bytes = try gpa.allocator.alloc(u8, 100);
//     defer gpa.allocator.free(bytes);
// }

const eql = std.mem.eql;
const ArrayList = std.ArrayList;
const test_allocator = std.testing.allocator;

test "arraylist" {
    var list = ArrayList(u8).init(test_allocator);
    defer list.deinit();
    try list.append('H');
    try list.append('e');
    try list.append('l');
    try list.append('l');
    try list.append('o');
    try list.appendSlice(" World");

    try expect(eql(u8, list.items, "Hello World"));
}

test "createFile, write, seekTo, read" {
    const file = try std.fs.cwd().createFile(
        "junk_file.txt",
        .{ .read = true },
    );
    defer file.close();

    const bytes_written = try file.writeAll("Hello, File!");
    _ = bytes_written;

    var buffer: [100]u8 = undefined;
    try file.seekTo(0);
    const bytes_read = try file.readAll(&buffer);
    try expect(eql(u8, buffer[0..bytes_read], "Hello, File!"));
}

test "file stat" {
    const file = try std.fs.cwd().createFile(
        "junk_file2.txt",
        .{},
    );
    defer file.close();
    const stat = try file.stat();
    try expect(stat.size == 0);
    try expect(stat.kind == .File);
    try expect(stat.ctime <= std.time.nanoTimestamp());
    try expect(stat.mtime <= std.time.nanoTimestamp());
    try expect(stat.atime <= std.time.nanoTimestamp());
}

test "make dir" {
    try std.fs.cwd().makeDir("test-tmp");
    const dir = try std.fs.cwd().openDir(
        "test-tmp",
        .{ .iterate = true },
    );
    defer {
        std.fs.cwd().deleteTree("test-tmp") catch unreachable;
    }

    _ = try dir.createFile("x", .{});
    _ = try dir.createFile("y", .{});
    _ = try dir.createFile("z", .{});

    var file_count: usize = 0;
    var iter = dir.iterate();
    while (try iter.next()) |entry| {
        if (entry.kind == .File) file_count += 1;
    }
    try expect(file_count == 3);
}

test "io writer usage" {
    var list = ArrayList(u8).init(test_allocator);
    defer list.deinit();
    const bytes_written = try list.writer().write(
        "Hello, World",
    );
    try expect(bytes_written == 12);
    try expect(eql(u8, list.items, "Hello, World"));
}

test "io reader usage" {
    const message = "Hello, File";

    const file = try std.fs.cwd().createFile(
        "junk_file2.txt",
        .{ .read = true },
    );
    defer file.close();

    try file.writeAll(message);
    try file.seekTo(0);

    const contents = try file.reader().readAllAlloc(
        test_allocator,
        message.len,
    );
    defer test_allocator.free(contents);

    try expect(eql(u8, contents, message));
}

fn nextLine(reader: anytype, buffer: []u8) !?[]const u8 {
    var line = (try reader.readUntilDelimiterOrEof(
        buffer,
        '\n',
    )) orelse return null;
    // try annoying windows-only carriage return character
    if (builtin.os.tag == .windows) {
        line = std.mem.trimRight(u8, line, "\r");
    }
    return line;
}

test "read until next line" {
    const stdout = std.io.getStdOut();
    const stdin = std.io.getStdIn();

    try stdout.writeAll(
        \\ Enter your name:
    );

    var buffer: [100]u8 = undefined;
    const input = (try nextLine(stdin.reader(), &buffer)).?;
    try stdout.writer().print(
        "Your name is: \"{s}\"\n",
        .{input},
    );
}

pub fn main() anyerror!void {
    std.log.info("All your codebase are belong to us.", .{});
}

test "basic test" {
    try std.testing.expectEqual(10, 3 + 7);
}
