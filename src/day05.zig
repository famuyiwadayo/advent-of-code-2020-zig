const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;
const String = []const u8;

const util = @import("util.zig");
const gpa = util.gpa;

const data = @embedFile("../data/day05.txt");

const Range = struct {
    min: usize = 0,
    max: usize = 0,
};

const Symbol = enum {
    F,
    B,
    L,
    R,

    pub fn fromChar(char: u8) Symbol {
        return switch (char) {
            'F', 'f' => .F,
            'B', 'b' => .B,
            'L', 'l' => .L,
            'R', 'r' => .R,
            else => @panic("Unsupported character"),
        };
    }
};

const BinaryBoarding = struct {
    seats: List(String) = undefined,
    allocator: Allocator = undefined,

    const Self = @This();

    const desc_usize = desc(usize);
    const asc_usize = asc(usize);

    const RowAndCol = struct {
        row: usize = 0,
        col: usize = 0,
    };

    pub fn init(allocator: Allocator) BinaryBoarding {
        return .{ .seats = List(String).init(allocator), .allocator = allocator };
    }

    pub fn deinit(self: *Self) void {
        self.seats.deinit();
        self.* = undefined;
    }

    pub fn parse(self: *Self, file: String) ![]String {
        var iterator = tokenize(u8, file, "\n");
        while (iterator.next()) |seat| try self.seats.append(seat);
        return self.seats.items;
    }

    /// Returns an Hashmap of the seat as key and the seatId as the value.
    /// e.g {"FFBFBBRLR": 405}
    /// Remember to free the space `StrMap(usize)` takes in memory;
    pub fn checkBinarySeats(self: *Self) !StrMap(usize) {
        var map = StrMap(usize).init(self.allocator);
        for (self.seats.items) |seat| {
            const seatId = try self.getSeatId(seat, false);
            try map.put(seat, seatId);
        }
        return map;
    }

    pub fn highestSeatId_partOne(self: *Self, seatIds: []usize) usize {
        _ = self;
        var id: usize = 0;
        for (seatIds) |seatId| {
            id = if (seatId > id) seatId else id;
        }
        return id;
    }

    pub fn mySeatId_partTwo(self: *Self, seatIds: []usize) !usize {
        _ = self;
        // _ = seatIds;

        var seats = try self.allocator.alloc(usize, seatIds.len);
        std.mem.copy(usize, seats, seatIds);
        sort(usize, seats, {}, asc_usize);

        // skip the very first and last seat at index
        // 0, and seat.len respectively as my_seat_id cannot be found there;
        var i: usize = 1;
        const last = seats.len - 1;

        while(i < last) : (i += 1) {
            const curr = seats[i];
            const next = i + 1;
            if(curr + 1 != seats[next]) return curr + 1;
        }
        return 0;
    }

    pub fn getSeatIds(self: *Self) ![]usize {
        var ids = List(usize).init(self.allocator);
        for (self.seats.items) |seat| {
            const seatId = try self.getSeatId(seat, false);
            try ids.append(seatId);
        }

        return ids.toOwnedSlice();
    }

    pub fn getSeatId(self: *Self, seat: String, debug: bool) !usize {
        _ = self;

        const row_str = seat[0..7];
        const col_str = seat[7..];

        const row = blk: {
            var result: usize = 0;
            var row_range: ?Range = null;
            for (row_str) |r| {
                const symbol = Symbol.fromChar(r);
                row_range = try self.useRangeStrategy(symbol, row_range);
                // print("{c}. --- row_range --- {any}\n", .{ r, row_range });
                if (row_range.?.min == row_range.?.max) result = row_range.?.min;
            }

            break :blk result;
        };

        // print("\n\n", .{});

        const col = blk: {
            var result: usize = 0;
            var col_range: ?Range = null;
            for (col_str) |c| {
                const symbol = Symbol.fromChar(c);
                col_range = try self.useRangeStrategy(symbol, col_range);
                // print("{c}. --- col_range --- {any}\n", .{ c, col_range });
                if (col_range.?.min == col_range.?.max) result = col_range.?.max;
            }

            break :blk result;
        };

        const id = row * 8 + col;
        if (debug) print("\n{s} ---> row = {}, col = {}, id = {}\n", .{ seat, row, col, id });
        return id;
    }

    fn useRangeStrategy(self: *Self, symbol: Symbol, range: ?Range) !Range {
        _ = self;

        const rng = if (range == null) self.getRange(symbol) else range.?;
        return switch (symbol) {
            .F, .L => Range{ .min = rng.min, .max = if (rng.max - rng.min > 2) util.mean2Floor(usize, rng.min, rng.max) else rng.min }, // lower half
            .B, .R => Range{
                .min = if (rng.max - rng.min > 2) try util.mean2Ceil(usize, rng.min, rng.max) else rng.max,
                .max = rng.max,
            }, // upper half
        };
    }

    fn getRange(self: *Self, symbol: Symbol) Range {
        _ = self;
        return switch (symbol) {
            .F, .B => Range{ .min = 0, .max = 127 }, // 128 exclusive
            .L, .R => Range{ .min = 0, .max = 7 }, // 8 exclusive
        };
    }
};

pub fn main() !void {
    var bb = BinaryBoarding.init(gpa);
    defer bb.deinit();
    _ = try bb.parse(data);
    const seatIds = try bb.getSeatIds();

    const highest_seat_id = bb.highestSeatId_partOne(seatIds);
    const my_seat_id = bb.mySeatId_partTwo(seatIds);

    print("Highest seat-id is {}\n", .{highest_seat_id});
    print("My seat-id is {}\n", .{my_seat_id});
}

// Useful stdlib functions
const tokenize = std.mem.tokenize;
const split = std.mem.split;
const indexOf = std.mem.indexOfScalar;
const indexOfAny = std.mem.indexOfAny;
const indexOfStr = std.mem.indexOfPosLinear;
const lastIndexOf = std.mem.lastIndexOfScalar;
const lastIndexOfAny = std.mem.lastIndexOfAny;
const lastIndexOfStr = std.mem.lastIndexOfLinear;
const trim = std.mem.trim;
const sliceMin = std.mem.min;
const sliceMax = std.mem.max;

const parseInt = std.fmt.parseInt;
const parseFloat = std.fmt.parseFloat;

const min = std.math.min;
const min3 = std.math.min3;
const max = std.math.max;
const max3 = std.math.max3;
const ceil = std.math.divCeil;

const print = std.debug.print;
const assert = std.debug.assert;

const sort = std.sort.sort;
const asc = std.sort.asc;
const desc = std.sort.desc;
