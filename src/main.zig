const std = @import("std");
const tzfile = @import("tzfile");

pub fn main() !void {
    var buffer: [8192]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();

    const timezone = try tzfile.Tz.open(allocator, "/usr/share/zoneinfo/Europe/Paris");
    std.debug.print("Tz struct tzh_timecnt  : {any}\n", .{timezone.tzh_timecnt_data});
    std.debug.print("Current timestamp      : {any}\n", .{std.time.timestamp()});
}

//test "simple test" {
//    var list = std.ArrayList(i32).init(std.testing.allocator);
//    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
//    try list.append(42);
//    try std.testing.expectEqual(@as(i32, 42), list.pop());
//}
