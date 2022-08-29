const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;
const Str = []const u8;

const util = @import("util.zig");
const gpa = util.gpa;

const data = @embedFile("../data/day01.txt");

// https://adventofcode.com/2020/day/1
pub fn main() !void {
    // print("Hello world", .{});

    const numbers = try getNumbers();

    const partOneValues = try partOne(numbers);
    const partTwoValues = try partTwo(numbers);

    print("{any} ----- {any}\n", .{ partOneValues, partTwoValues });
}

fn partTwo(numbers: []usize) ![]usize {
    var values = List(usize).init(gpa);

    for (numbers) |n0, i| {
        for (numbers[i + 1 ..]) |n1, j| {
            if (i + 1 == numbers.len + 1) @panic("Bad loop!!");
            for (numbers[j + 1 ..]) |n2| {
                if (j + 1 == numbers.len + 1) @panic("Bad loop!!");
                if (n0 + n1 + n2 == 2020) {
                    print("PART TWO --> Found the numbers, {} * {} * {} = {}\n", .{ n0, n1, n2, n0 * n1 * n2 });
                    try values.appendSlice(&[3]usize{ n0, n1, n2 });
                    return values.toOwnedSlice();
                }
            }
        }
    }

    return values.toOwnedSlice();
}

fn partOne(numbers: []const usize) ![]usize {
    var values = List(usize).init(gpa);
    for (numbers) |n0, i| {
        for (numbers[i + 1 ..]) |n1| {
            if (i + 1 == numbers.len + 1) @panic("Bad loop!!");
            if (n0 + n1 == 2020) {
                print("PART ONE --> Found the numbers, {} * {} = {}\n", .{ n0, n1, n0 * n1 });
                try values.appendSlice(&[2]usize{ n0, n1 });
                return values.toOwnedSlice();
            }
        }
    }

    return values.toOwnedSlice();
}

fn getNumbers() ![]usize {
    var numbers = List(usize).init(gpa);
    var line_it = tokenize(u8, data, "\n");

    while (line_it.next()) |line| {
        const num = try parseInt(usize, line, 10);
        try numbers.append(num);
    }

    return numbers.toOwnedSlice();
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

const print = std.debug.print;
const assert = std.debug.assert;

const sort = std.sort.sort;
const asc = std.sort.asc;
const desc = std.sort.desc;
