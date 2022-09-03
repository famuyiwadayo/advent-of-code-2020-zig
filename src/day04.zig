const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;
const String = []const u8;

const util = @import("util.zig");
const gpa = util.gpa;

const data = @embedFile("../data/day04.txt");

const StringMap = StrMap(String);

const Unit = enum {
    cm,
    in,
    pub fn fromString(value: String) Unit {
        return std.meta.stringToEnum(Unit, value) orelse @panic("Height unit unsupported");
    }
};

const PassportField = enum {
    byr, // birth year
    iyr, // issue year
    eyr, // expiration year
    hgt, // height in (cm | in)
    hcl, // hair color
    ecl, // eye color
    pid, // passport id
    cid, // country id

    pub fn fromString(value: String) PassportField {
        return std.meta.stringToEnum(PassportField, value) orelse @panic("Character unknown");
    }

    pub fn isValid(self: PassportField, value: String) !bool {
        return switch (self) {
            .byr => try self.validate_byr(value),
            .iyr => try self.validate_iyr(value),
            .eyr => try self.validate_eyr(value),
            .hgt => try self.validate_hgt(value),
            .hcl => try self.validate_hcl(value),
            .ecl => try self.validate_ecl(value),
            .pid => try self.validate_pid(value),
            .cid => try self.validate_cid(value),
        };
    }

    /// Four digits; at least 1920 and at most 2002.
    fn validate_byr(self: PassportField, value: String) !bool {
        _ = self;
        const v_int = try parseInt(u16, value, 10);
        if (value.len < 4) return false;
        if (v_int < 1920 or v_int > 2002) return false;
        return true;
    }

    /// Four digits; at least 2010 and at most 2020.
    fn validate_iyr(self: PassportField, value: String) !bool {
        _ = self;
        const v_int = try parseInt(u16, value, 10);
        if (value.len < 4) return false;
        if (v_int < 2010 or v_int > 2020) return false;
        return true;
    }

    /// Four digits; at least 2020 and at most 2030.
    fn validate_eyr(self: PassportField, value: String) !bool {
        _ = self;
        const v_int = try parseInt(u16, value, 10);
        if (value.len < 4) return false;
        if (v_int < 2020 or v_int > 2030) return false;
        return true;
    }

    /// A number followed by either cm or in:
    /// If cm, the number must be at least 150 and at most 193.
    /// If in, the number must be at least 59 and at most 76.
    fn validate_hgt(self: PassportField, value: String) !bool {
        _ = self;
        const num_string = tokenize(u8, value, "cmin").next(); // strip cm and in then return the number
        const unit_string = tokenize(u8, value, num_string.?).next(); // tokenize with the num_string to get the unit string


        if(num_string == null or unit_string == null) return false;

        const unit = Unit.fromString(unit_string.?);
        const number = try parseInt(u16, num_string.?, 10);

        return switch (unit) {
            .cm => if (number < 150 or number > 193) false else true,
            .in => if (number < 59 or number > 76) false else true,
        };
    }

    /// A # followed by exactly six characters 0-9 or a-f.
    fn validate_hcl(self: PassportField, value: String) !bool {
        _ = self;
        _ = value;

        const hexIdx = indexOf(u8, value, '#');
        if (hexIdx == null) return false;

        const rgbHex = value[hexIdx.? + 1 ..];
        if (rgbHex.len < 6 or rgbHex.len > 6) return false;
        for (rgbHex) |char| if (!std.ascii.isXDigit(char)) return false;

        return true;
    }

    /// Exactly one of: amb blu brn gry grn hzl oth.
    fn validate_ecl(self: PassportField, value: String) !bool {
        _ = self;
        if (value.len < 3 or value.len > 3) return false;
        var knownEcl = [_]String{ "amb", "blu", "brn", "gry", "grn", "hzl", "oth" };
        return util.includes(&knownEcl, value);
    }

    /// A nine-digit number, including leading zeroes.
    fn validate_pid(self: PassportField, value: String) !bool {
        _ = self;
        if (value.len > 9 or value.len < 9) return false;
        const id = try parseInt(u32, value, 10);
        if (id <= 0 and id > 999999999) return false;
        return true;
    }

    /// Ignored, missing or not.
    fn validate_cid(self: PassportField, value: String) !bool {
        _ = self;
        _ = value;
        return true;
    }
};

const Processor = struct {
    db: List(StringMap),
    allocator: Allocator,
    const Self = @This();

    const Result = struct {
        valid: usize = 0,
        invalid: usize = 0,
    };

    pub fn init(allocator: Allocator) Processor {
        return Processor{ .db = List(StringMap).init(allocator), .allocator = allocator };
    }

    pub fn deinit(self: *Self) void {
        defer print("FREED ALL USED MEMORY\n\n", .{}); // last call
        defer self.* = undefined; // third call
        defer self.db.deinit(); // second call
        for (self.db.items) |*pass| pass.deinit(); // first call
    }

    pub fn parse(self: *Self, passports: String) ![]StringMap {
        var iterator = split(u8, passports, "\n\n");

        while (iterator.next()) |passport| {
            var map = StringMap.init(self.allocator);
            var details = tokenize(u8, passport, " \n");
            // defer map.deinit();

            while (details.next()) |detail| {
                var pair = split(u8, detail, ":");
                const key = pair.next().?;
                const value = pair.next().?;
                try map.put(key, value);
                // print("key={s}, value={s} ---> ", .{ key, value });
            }
            try self.db.append(map);
        }

        return self.db.items;
    }

    pub fn check_partOne(self: *Self, passports: []StringMap) !Result {
        _ = self;
        _ = passports;

        // remove cid temporarily
        var requirements = [_]String{ "byr", "iyr", "eyr", "hgt", "hcl", "ecl", "pid" };

        var valid: usize = 0;
        var invalid: usize = 0;

        for (passports) |pass| {
            const missing = blk: {
                var list = List(String).init(self.allocator);
                for (requirements) |req| {
                    if (!pass.contains(req)) try list.append(req);
                }
                break :blk list.toOwnedSlice();
            };

            if (missing.len == 0) valid += 1 else invalid += 1;
            // print("{s} - len = {}\n\n", .{missing, missing.len});
        }

        return Result{ .valid = valid, .invalid = invalid };
    }

    pub fn check_partTwo(self: *Self, passports: []StringMap) !Result {
        _ = self;
        _ = passports;

        // remove cid temporarily
        var requirements = [_]String{ "byr", "iyr", "eyr", "hgt", "hcl", "ecl", "pid" };

        var valid: usize = 0;
        var invalid: usize = 0;

        for (passports) |pass| {
            const missing = blk: {
                var list = List(String).init(self.allocator);
                for (requirements) |req| {
                    if (!pass.contains(req)) {
                        try list.append(req);
                        continue;
                    }
                    const value = pass.get(req).?;
                    const isValid = try PassportField.fromString(req).isValid(value);
                    // print("{}.  key = {s}, value = {s}, isValid = {any}\n", .{i+1,req, value, isValid});
                    if (!isValid) try list.append(req);
                }
                break :blk list.toOwnedSlice();
            };

            if (missing.len == 0) valid += 1 else invalid += 1;
            // print("{s} - len = {}\n\n", .{missing, missing.len});
            // break;
        }

        return Result{ .valid = valid, .invalid = invalid };
    }
};

pub fn main() !void {

    // var iterator = split(u8, data, "\n\n");

    // while(iterator.next()) |line| {
    //     print("{s}\n\n", .{line});
    // }

    var processor = Processor.init(gpa);
    defer processor.deinit();
    const passports = try processor.parse(data);
    const partOneResult = try processor.check_partOne(passports);
    const partTwoResult = try processor.check_partTwo(passports);

    print("PART ONE --> {any}\n", .{partOneResult});
    print("PART TWO --> {any}\n", .{partTwoResult});

    // const field = PassportField.fromString("hcl").isValid("#acrfff");

    // print("{any}\n", .{field});

    // var list = [_]String{ "a", "b", "c" };

    // print("List includes a = {any}\n", .{includes(&list, "f")});

    // print("\n\n\n{any}\n", .{passports});
    // for (passports) |pass| {
    //     var keys = pass.keyIterator();
    //     while (keys.next()) |key| print("\n\n\nkey -->{s},   value --> {s}", .{ key.*, pass.get(key.*) });
    // }
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
const eql = std.mem.eql;
