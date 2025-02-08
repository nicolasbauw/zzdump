const std = @import("std");
const tzfile = @import("tzfile");

pub fn main() !void {
    var buffer: [8192]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();

    const timezone = try tzfile.Tz.open(allocator, "/usr/share/zoneinfo/Europe/Paris");
    defer timezone.close();

    const last = getLastTT(timezone.timecnt_data);
    const last_ttinfo = timezone.typecnt[timezone.timecnt_indices[last[1]]];
    //std.debug.print("Tz struct                  : {any}\n", .{timezone});
    std.debug.print("Current timestamp          : {any}\n", .{std.time.timestamp()});
    std.debug.print("Latest change timestamp    : {any}\n", .{last[0]});
    std.debug.print("Latest change ttinfo       : {any}\n", .{last_ttinfo});
}

fn getLastTT(timecnt: []const i64) struct { i64, usize } {
    const current = std.time.timestamp();
    var latest_tt: struct { i64, usize } = .{ undefined, undefined };

    for (timecnt, 0..) |time, index| {
        if (time < current) {
            latest_tt[0] = time;
            latest_tt[1] = index;
        }
    }

    return latest_tt;
}

//test "simple test" {
//    var list = std.ArrayList(i32).init(std.testing.allocator);
//    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
//    try list.append(42);
//    try std.testing.expectEqual(@as(i32, 42), list.pop());
//}
