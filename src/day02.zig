const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;
const Str = []const u8;

const util = @import("util.zig");
const gpa = util.gpa;

const data = @embedFile("../data/day02.txt");

const PasswordAndPolicy = struct {
    min: usize = 0,
    max: usize = 0,
    char: u8 = undefined,
    password: []const u8 = undefined,

    pub fn init(min: usize, max: usize, char: u8, password: []const u8) PasswordAndPolicy {
        return PasswordAndPolicy{ .min = min, .max = max, .char = char, .password = password };
    }
};

const Checkr = struct {
    db: List(PasswordAndPolicy) = undefined,
    allocator: Allocator = undefined,
    const Self = @This();

    const Result = struct {
        valid: usize = 0,
        invalid: usize = 0,
    };

    pub fn init(allocator: Allocator) Checkr {
        return Checkr{ .db = List(PasswordAndPolicy).init(allocator), .allocator = allocator };
    }

    pub fn deinit(self: *Self) void {
        self.db.deinit();
    }

    pub fn parsePolicies(self: *Self, policies: []const u8) ![]PasswordAndPolicy {
        var iterator = tokenize(u8, policies, "\n");
        while (iterator.next()) |line| {
            var tokens = tokenize(u8, line, "- :");
            const min = try parseInt(usize, tokens.next().?, 10);
            const max = try parseInt(usize, tokens.next().?, 10);
            const char = tokens.next().?[0];
            const password = tokens.next().?;

            try self.db.append(PasswordAndPolicy.init(min, max, char, password));
        }

        return self.db.items;
    }

    pub fn checkPasswords_partOne(_: *Self, passwordAndPolicies: []PasswordAndPolicy) Result {
        var valid: usize = 0;
        var invalid: usize = 0;
        for (passwordAndPolicies) |pnp| {
            const count = blk: { // open a block
                var tempc: usize = 0; // temporary count;
                for (pnp.password) |letter| {
                    if (letter == pnp.char) tempc += 1;
                }
                break :blk tempc; // break outta block and return tempc;
            };

            // print("on line {}: --- {c} occurred {} times in {s}\n\n", .{i + 1, pnp.char, count, pnp.password});

            if(count >= pnp.min and count <= pnp.max) valid += 1
            else invalid += 1;
        }

        return Result{ .valid = valid, .invalid = invalid };
    }

    pub fn checkPasswords_partTwo(_: *Self, passwordAndPolicies: []PasswordAndPolicy) Result {
        var valid: usize = 0;
        var invalid: usize = 0;
        for (passwordAndPolicies) |pnp| {

            // print("on line {}: [{s}] char at position {} = {c}, position {} = {c}\n\n", 
            // .{i+1, pnp.password, pnp.min, pnp.password[pnp.min-1], pnp.max, pnp.password[pnp.max-1]});

            if(
                pnp.password[pnp.min - 1] == pnp.char and pnp.password[pnp.max - 1] != pnp.char or
                pnp.password[pnp.min - 1] != pnp.char and pnp.password[pnp.max - 1] == pnp.char
            ) valid += 1
            else invalid += 1;

        }

        return Result{ .valid = valid, .invalid = invalid };
    }
};

pub fn main() !void {

    var checkr = Checkr.init(gpa);
    defer checkr.deinit();

    const list = try checkr.parsePolicies(data);

    // for (list) |policy| {
    //     print("min={any}, ---  max={any}, ---  char={c} --- password={s} \n", .{ policy.min, policy.max, policy.char, policy.password });
    // }

    const partOneResult = checkr.checkPasswords_partOne(list);
    const partTwoResult = checkr.checkPasswords_partTwo(list);

    print("PART ONE --> {} Valid and {} Invalid passwords found in total of {} passwords\n", .{partOneResult.valid, partOneResult.invalid, list.len});
    print("PART TWO --> {} Valid and {} Invalid passwords found in total of {} passwords\n", .{partTwoResult.valid, partTwoResult.invalid, list.len});
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

// const min = std.math.min;
// const min3 = std.math.min3;
// const max = std.math.max;
// const max3 = std.math.max3;

const print = std.debug.print;
const assert = std.debug.assert;

const sort = std.sort.sort;
const asc = std.sort.asc;
const desc = std.sort.desc;
