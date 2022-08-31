const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;
const Str = []const u8;

const util = @import("util.zig");
const gpa = util.gpa;

const data = @embedFile("../data/day03.txt");

const Object = enum(u2) {
    space = 0,
    tree,

    pub fn fromChar(char: u8) Object {
        return switch (char) {
            '.' => .space,
            '#' => .tree,
            else => @panic("character unknown"),
        };
    }

    pub fn toChar(self: Object) u8 {
        return switch (self) {
            .space => '.',
            .tree => '#',
        };
    }

    pub fn toInt(self: Object) u2 {
        return @enumToInt(self);
    }
};

const Strategy = struct {
    right: u8,
    down: u8,
};

const Result = struct {
    trees: usize = 0,
    spaces: usize = 0,

    pub fn mult(self: Result, other: Result) Result {
        return Result{ .trees = self.trees * other.trees, .spaces = self.spaces * other.spaces };
    }
};

const Snow = struct {
    map: List([]u2),
    allocator: Allocator,
    const Self = @This();

    pub fn init(allocator: Allocator) Snow {
        return Snow{ .map = List([]u2).init(allocator), .allocator = allocator };
    }

    pub fn deinit(self: Self) void {
        self.map.deinit();
    }

    pub fn parse(self: *Self, rawMap: []const u8) ![][]u2 {
        var iterator = tokenize(u8, rawMap, "\n");
        while (iterator.next()) |line| {
            var slope = List(u2).init(self.allocator);
            for (line) |char| try slope.append(Object.fromChar(@as(u8, char)).toInt());
            try self.map.append(slope.toOwnedSlice());
        }

        return self.map.items;
    }

    pub fn checkTrees(self: Self, map: [][]u2, stragy: Strategy) Result {
        _ = self;
        var trees: usize = 0;
        var spaces: usize = 0;

        var row: usize = 0;
        var currentCol: usize = 0;
        while (row < map.len) : (row += stragy.down) {
            const nextRow = row + stragy.down;
            // use of MOD explained by Jonathan Chow on youtube [https://www.youtube.com/watch?v=j2fr-TQJwzA&t=23s];
            currentCol = @mod(currentCol + stragy.right, map[0].len);

            if (nextRow >= map.len) break;
            const value = map[nextRow][currentCol];

            if (value == 0) spaces += 1 else trees += 1;
        }

        return Result{ .trees = trees, .spaces = spaces };
    }
};

pub fn main() !void {
    var snow = Snow.init(gpa);
    defer snow.deinit();
    const map = try snow.parse(data);

    const part_one_result = snow.checkTrees(map, .{ .right = 3, .down = 1 });
    print("PART ONE --> {any}\n", .{part_one_result});

    const strategies = [_]Strategy{
        .{ .right = 1, .down = 1 },
        .{ .right = 3, .down = 1 },
        .{ .right = 5, .down = 1 },
        .{ .right = 7, .down = 1 },
        .{ .right = 1, .down = 2 },
    };

    // 1 is neutral for the multiplication|division operation;
    // would be 0 if we were performing an addition|subtraction operation;
    var part_two_result = Result{ .trees = 1, .spaces = 1 };

    for (strategies) |stragy| {
        const res = snow.checkTrees(map, stragy);
        part_two_result = part_two_result.mult(res);
    }

    print("PART TWO --> {any}\n", .{part_two_result});
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
