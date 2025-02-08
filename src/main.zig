const std = @import("std");
const tzfile = @import("tzfile");

// 16K in the BSS segment for the Fixed Buffer Allocator
var bss: [16384]u8 = undefined;

pub fn main() !void {
    var fba = std.heap.FixedBufferAllocator.init(&bss);
    const allocator = fba.allocator();

    const timezone = try tzfile.Tz.open(allocator, "/usr/share/zoneinfo/Europe/Paris");
    defer timezone.close();

    // Getting last timechange data
    const last = getLastTT(timezone.time_data);
    const last_ttinfo = timezone.time_types[timezone.time_indices[last[1]]];

    // Getting abbreviation for this timetype
    const start_index = last_ttinfo.tt_desigidx;
    var end_index = start_index;

    for (timezone.tt_desig[start_index..]) |c| {
        if (c != 0) {
            end_index += 1;
        } else {
            break;
        }
    }

    std.debug.print("Current timestamp          : {any}\n", .{std.time.timestamp()});
    std.debug.print("Latest change timestamp    : {any}\n", .{last[0]});
    std.debug.print("Latest change ttinfo       : {any}\n", .{last_ttinfo});
    std.debug.print("Latest change abbr         : {s}\n", .{timezone.tt_desig[start_index..end_index]});
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

test "get last timechange" {
    const timezone = try tzfile.Tz.open(std.testing.allocator, "/usr/share/zoneinfo/America/Phoenix");
    defer timezone.close();
    const last = getLastTT(timezone.time_data);
    try std.testing.expectEqual(last[0], @as(i64, -68659200));
}
