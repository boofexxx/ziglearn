const std = @import("std");
const expect = @import("std").testing.expect;

var foo: i32 = 1;

test "suspend with no resume" {
    var frame = async func(); //1
    _ = frame;
    try expect(foo == 2); //4
}

fn func() void {
    foo += 1; //2
    suspend {} //3
    foo += 1; //never reached!
}

var bar: i32 = 1;

test "suspend with resume" {
    var frame = async func2(); // 1
    resume frame; // 4
    try expect(bar == 3); // 6
}

fn func2() void {
    bar += 1; // 2
    suspend {} // 3
    bar += 1; // 5
}

fn func3() u32 {
    return 5;
}

test "async / await" {
    var frame = async func3();
    try expect(await frame == 5);
}

pub fn main() anyerror!void {
    std.log.info("All your codebase are belong to us.", .{});
}

test "basic test" {
    try std.testing.expectEqual(10, 3 + 7);
}
