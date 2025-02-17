const std = @import("std");
const Tz = @import("tzfile").Tz;
const DateTime = @import("datetime").DateTime;

// 16K in the BSS segment for the Fixed Buffer Allocator
var bss: [16384]u8 = undefined;

pub fn main() void {
    var fba = std.heap.FixedBufferAllocator.init(&bss);
    const allocator = fba.allocator();

    const stdout = std.io.getStdOut().writer();

    const timezone = Tz.open(allocator, "/usr/share/zoneinfo/Europe/Paris") catch |err| {
        stdout.print("Cannot open file : {}\n", .{err}) catch {};
        std.process.exit(1);
    };
    defer timezone.close();

    // Getting last timechange data
    const last = getPrevTT(timezone.time_data, std.time.timestamp());
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

    const ts = std.time.milliTimestamp();
    const dt = DateTime.fromMillis(ts);

    std.debug.print("Current timestamp      : {any}\n", .{ts});
    std.debug.print("Current date/time      : {any}\n", .{dt});
    std.debug.print("Last change timestamp  : {any}\n", .{last[0]});
    std.debug.print("Last change date/time  : {any}\n", .{DateTime.fromMillis(last[0] * 1000)});
    std.debug.print("Last change ttinfo     : {any}\n", .{last_ttinfo});
    std.debug.print("Last change abbr       : {s}\n", .{timezone.tt_desig[start_index..end_index]});

    std.process.cleanExit();
}

fn getPrevTT(timecnt: []const i64, ref_time: i64) struct { i64, usize } {
    var last_tt: struct { i64, usize } = .{ undefined, undefined };

    for (timecnt, 0..) |time, index| {
        if (time < ref_time) {
            last_tt[0] = time;
            last_tt[1] = index;
        }
    }

    return last_tt;
}

test "get last timechange" {
    const timezone = try Tz.open(std.testing.allocator, "/usr/share/zoneinfo/America/Phoenix");
    defer timezone.close();
    const last = getPrevTT(timezone.time_data);
    try std.testing.expectEqual(last[0], @as(i64, -68659200));
}
