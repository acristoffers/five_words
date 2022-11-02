const std = @import("std");

const Word = std.meta.Tuple(&.{ [5]u8, u32 });
const WordList = std.ArrayList(Word);

fn WordListHashMap(comptime key: type) type {
    return std.AutoArrayHashMap(key, WordList);
}

fn letters(word: []const u8) u32 {
    var i: u32 = 0;
    for (word) |c| i |= (@as(u32, 1) << @truncate(u5, c - 97));
    return i;
}

fn appendToVowel(words_with_vowels: *WordListHashMap(u8), word: Word) !void {
    const a: u32 = @as(u32, 1) << @truncate(u5, 'a' - 'a');
    const e: u32 = @as(u32, 1) << @truncate(u5, 'e' - 'a');
    const i: u32 = @as(u32, 1) << @truncate(u5, 'i' - 'a');
    const o: u32 = @as(u32, 1) << @truncate(u5, 'o' - 'a');
    const u: u32 = @as(u32, 1) << @truncate(u5, 'u' - 'a');
    const all_vowels = a | e | i | o | u;
    const vowels = word[1] & all_vowels;
    const n_vowels = @popCount(vowels);
    const key = switch (n_vowels) {
        1 => switch (vowels) {
            a => @as(u8, 'a'),
            e => @as(u8, 'e'),
            i => @as(u8, 'i'),
            o => @as(u8, 'o'),
            u => @as(u8, 'u'),
            else => unreachable,
        },
        2 => 'p',
        0 => 'm',
        else => 'z',
    };
    try (try words_with_vowels.getOrPut(key)).value_ptr.append(word);
}

const WordPair = std.meta.Tuple(&.{ [2][]const u8, u32 });
const WordPairList = std.ArrayList(WordPair);
fn uniqueCombinations(allocator: std.mem.Allocator, a: *const WordList, b: *const WordList) !WordPairList {
    var list = try WordPairList.initCapacity(allocator, 100000);
    for (a.items) |*word1| {
        for (b.items) |*word2| {
            if (word1.@"1" & word2.@"1" == 0) {
                const pair: WordPair = .{ .{ &word1.@"0", &word2.@"0" }, word1.@"1" | word2.@"1" };
                try list.append(pair);
            }
        }
    }
    return list;
}

const WordQuartet = std.meta.Tuple(&.{ [4][]const u8, u32 });
const WordQuartetList = std.ArrayList(WordQuartet);
fn uniqueCombinationsQuartet(allocator: std.mem.Allocator, a: WordPairList, b: WordPairList) !WordQuartetList {
    var list = try WordQuartetList.initCapacity(allocator, 100000);
    for (a.items) |word1| {
        for (b.items) |word2| {
            if (word1[1] & word2[1] == 0) {
                const quartet: WordQuartet = .{ word1[0] ++ word2[0], word1[1] | word2[1] };
                try list.append(quartet);
            }
        }
    }
    return list;
}

var _memoPairTable: ?std.AutoArrayHashMap(u32, WordPairList) = null;
pub fn memoPair(allocator: std.mem.Allocator, vowels: WordListHashMap(u8), v1: u8, v2: u8) !WordPairList {
    if (_memoPairTable == null) {
        _memoPairTable = std.AutoArrayHashMap(u32, WordPairList).init(allocator);
    }

    const key = letters(&@as([5]u8, .{ v1, v1, v1, v1, v2 }));
    var value = try _memoPairTable.?.getOrPut(key);
    if (value.found_existing) {
        return value.value_ptr.*;
    }

    std.debug.print("\t\tSearching for solutions for [{c} {c}]...\n", .{ v1, v2 });

    const l1 = vowels.getPtr(v1).?;
    const l2 = vowels.getPtr(v2).?;

    value.value_ptr.* = try uniqueCombinations(allocator, l1, l2);

    std.debug.print("\t\tFound {} solutions.\n", .{value.value_ptr.items.len});

    return value.value_ptr.*;
}

var _memoQuartetTable: ?std.AutoArrayHashMap(u32, WordQuartetList) = null;
pub fn memoQuartet(allocator: std.mem.Allocator, vowels: WordListHashMap(u8), v1: u8, v2: u8, v3: u8, v4: u8) !WordQuartetList {
    if (_memoQuartetTable == null) {
        _memoQuartetTable = std.AutoArrayHashMap(u32, WordQuartetList).init(allocator);
    }

    const key = letters(&@as([5]u8, .{ v1, v1, v2, v3, v4 }));
    var value = try _memoQuartetTable.?.getOrPut(key);
    if (value.found_existing) {
        return value.value_ptr.*;
    }

    std.debug.print("\tSearching for solutions for [{c} {c} {c} {c}]...\n", .{ v1, v2, v3, v4 });

    const pair1 = try memoPair(allocator, vowels, v1, v2);
    const pair2 = try memoPair(allocator, vowels, v3, v4);

    value.value_ptr.* = try uniqueCombinationsQuartet(allocator, pair1, pair2);

    std.debug.print("\tFound {} solutions.\n", .{value.value_ptr.items.len});

    return value.value_ptr.*;
}

const WordQuintet = std.meta.Tuple(&.{ [5][]const u8, u32 });
const WordQuintetList = std.ArrayList(WordQuintet);
pub fn memoQuintet(allocator: std.mem.Allocator, vowels: WordListHashMap(u8), v1: u8, v2: u8, v3: u8, v4: u8, v5: u8) !WordQuintetList {
    const cs: [5][5]u8 = .{ .{ v1, v2, v3, v4, v5 }, .{ v1, v2, v3, v5, v4 }, .{ v1, v2, v4, v5, v3 }, .{ v1, v3, v4, v5, v2 }, .{ v2, v3, v4, v5, v1 } };
    var quartet: ?WordQuartetList = null;
    var v: ?WordList = null;
    if (_memoQuartetTable != null) {
        for (cs) |c| {
            if (_memoQuartetTable.?.get(letters((c[0..4] ++ c[0..1])))) |q| {
                quartet = q;
                v = vowels.get(c[4]).?;
                break;
            }
        }
    }

    std.debug.print("Searching for solutions for [{c} {c} {c} {c} {c}]...\n", .{ v1, v2, v3, v4, v5 });

    if (quartet == null) {
        quartet = try memoQuartet(allocator, vowels, v1, v2, v3, v4);
        v = vowels.get(v5).?;
    }

    var list = try WordQuintetList.initCapacity(allocator, 100000);
    for (quartet.?.items) |word1| {
        for (v.?.items) |*word2| {
            if (word1.@"1" & word2.@"1" == 0) {
                const w2: []const u8 = &word2.@"0";
                const vec: [5][]const u8 = .{ word1.@"0"[0], word1.@"0"[1], word1.@"0"[2], word1.@"0"[3], w2 };
                const quintet: WordQuintet = .{ vec, word1.@"1" | word2.@"1" };
                try list.append(quintet);
            }
        }
    }

    std.debug.print("Found {} solutions.\n", .{list.items.len});

    return list;
}

fn combinations(allocator: std.mem.Allocator, elements: []const u8, comptime n: usize) !std.ArrayList([n]u8) {
    var result = std.ArrayList([n]u8).init(allocator);
    if (elements.len < n) return result;
    var indices = [_]usize{0} ** n;
    var reversed = [_]usize{0} ** n;
    for (indices) |_, i| {
        indices[i] = i;
        reversed[i] = n - i - 1;
    }
    try result.append(elements[0..n].*);
    while (true) {
        var i: usize = 0;
        for (reversed) |k| {
            if (indices[k] != k + elements.len - n) {
                i = k;
                break;
            }
        } else {
            return result;
        }
        indices[i] += 1;
        var j = i + 1;
        while (j < n) : (j += 1) {
            indices[j] = indices[j - 1] + 1;
        }
        var tmp = [_]u8{0} ** n;
        for (indices) |a, b| tmp[b] = elements[a];
        try result.append(tmp);
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    var anagrams = WordListHashMap(u32).init(allocator);
    defer {
        for (anagrams.keys()) |k| if (anagrams.get(k)) |v| v.deinit();
        anagrams.deinit();
    }

    var words_with_vowels = WordListHashMap(u8).init(allocator);
    defer {
        for (words_with_vowels.keys()) |k| if (words_with_vowels.get(k)) |v| v.deinit();
        words_with_vowels.deinit();
    }

    try words_with_vowels.put('a', WordList.init(allocator));
    try words_with_vowels.put('e', WordList.init(allocator));
    try words_with_vowels.put('i', WordList.init(allocator));
    try words_with_vowels.put('o', WordList.init(allocator));
    try words_with_vowels.put('u', WordList.init(allocator));
    try words_with_vowels.put('p', WordList.init(allocator));
    try words_with_vowels.put('m', WordList.init(allocator));
    try words_with_vowels.put('z', WordList.init(allocator));

    {
        const file = try std.fs.cwd().openFile("words.txt", .{});
        defer file.close();

        var buf_reader = std.io.bufferedReader(file.reader());
        var in_stream = buf_reader.reader();

        var buf: [50]u8 = undefined;
        while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
            if (line.len == 5) {
                const l = letters(line[0..5]);
                if (@popCount(l) == 5) {
                    const word: Word = .{ line[0..5].*, l };
                    var v = try anagrams.getOrPut(l);
                    if (v.found_existing) {
                        try v.value_ptr.append(word);
                    } else {
                        v.value_ptr.* = WordList.init(allocator);
                        try v.value_ptr.append(word);
                        try appendToVowel(&words_with_vowels, word);
                    }
                }
            }
        }
    }

    var num_words: usize = 0;
    num_words += if (words_with_vowels.get('a')) |a| a.items.len else 0;
    num_words += if (words_with_vowels.get('e')) |a| a.items.len else 0;
    num_words += if (words_with_vowels.get('i')) |a| a.items.len else 0;
    num_words += if (words_with_vowels.get('o')) |a| a.items.len else 0;
    num_words += if (words_with_vowels.get('u')) |a| a.items.len else 0;
    num_words += if (words_with_vowels.get('m')) |a| a.items.len else 0;
    num_words += if (words_with_vowels.get('p')) |a| a.items.len else 0;
    num_words += if (words_with_vowels.get('z')) |a| a.items.len else 0;

    std.debug.print("Number of words: {d}\n", .{num_words});
    std.debug.print("Number of words with a: {d}\n", .{if (words_with_vowels.get('a')) |a| a.items.len else 0});
    std.debug.print("Number of words with e: {d}\n", .{if (words_with_vowels.get('e')) |a| a.items.len else 0});
    std.debug.print("Number of words with i: {d}\n", .{if (words_with_vowels.get('i')) |a| a.items.len else 0});
    std.debug.print("Number of words with o: {d}\n", .{if (words_with_vowels.get('o')) |a| a.items.len else 0});
    std.debug.print("Number of words with u: {d}\n", .{if (words_with_vowels.get('u')) |a| a.items.len else 0});
    std.debug.print("Number of words without vowels: {d}\n", .{if (words_with_vowels.get('m')) |a| a.items.len else 0});
    std.debug.print("Number of words with 2 vowels: {d}\n", .{if (words_with_vowels.get('p')) |a| a.items.len else 0});
    std.debug.print("Number of words with more than 2 vowels: {d}\n", .{if (words_with_vowels.get('z')) |a| a.items.len else 0});

    var cs = std.ArrayList([5]u8).init(allocator);
    defer cs.deinit();

    {
        var as = try combinations(allocator, "aeioummmmmppz", 5);
        defer as.deinit();

        for (as.items) |a| {
            // a not in cs
            const c1 = for (cs.items) |c| {
                if (std.mem.eql(u8, &a, &c)) break false;
            } else true;

            // max 5 vowels
            const c2 = c2: {
                var count: u8 = 0;
                for (a) |char| {
                    switch (char) {
                        'm' => {},
                        'p' => count += 2,
                        'z' => count += 3,
                        else => count += 1,
                    }
                }
                break :c2 count <= 5;
            };

            if (c1 and c2) {
                try cs.append(a);
            }
        }
    }

    std.debug.print("Number of combinations: {d}\n", .{cs.items.len});

    var solution = try WordQuintetList.initCapacity(allocator, 1000);
    defer solution.deinit();

    for (cs.items) |c| {
        const result = try memoQuintet(allocator, words_with_vowels, c[0], c[1], c[2], c[3], c[4]);
        defer result.deinit();
        try solution.appendSlice(result.items);
    }

    var solution_with_anagrams = try WordQuintetList.initCapacity(allocator, 1000);
    defer solution_with_anagrams.deinit();

    for (solution.items) |sol| {
        const a1 = anagrams.getPtr(letters(sol[0][0])).?;
        const a2 = anagrams.getPtr(letters(sol[0][1])).?;
        const a3 = anagrams.getPtr(letters(sol[0][2])).?;
        const a4 = anagrams.getPtr(letters(sol[0][3])).?;
        const a5 = anagrams.getPtr(letters(sol[0][4])).?;
        for (a1.items) |*w1| {
            for (a2.items) |*w2| {
                for (a3.items) |*w3| {
                    for (a4.items) |*w4| {
                        for (a5.items) |*w5| {
                            const s: WordQuintet = .{ .{ &w1.@"0", &w2.@"0", &w3.@"0", &w4.@"0", &w5.@"0" }, w1.@"1" | w2.@"1" | w3.@"1" | w4.@"1" | w5.@"1" };
                            try solution_with_anagrams.append(s);
                        }
                    }
                }
            }
        }
    }

    std.debug.print("Number of elements in solution: {d}\n", .{solution_with_anagrams.items.len});

    // For some reason there are repeated elements. Remove them.
    solution.clearRetainingCapacity();
    f1: for (solution_with_anagrams.items) |*sol| {
        for (solution.items) |*sol2| {
            var count: u8 = 0;
            for (sol.@"0") |s| {
                f2: for (sol2.@"0") |s2| {
                    if (std.mem.eql(u8, s, s2)) {
                        count += 1;
                        break :f2;
                    }
                }
            }
            if (count == 5) {
                continue :f1;
            }
        }
        try solution.append(sol.*);
    }

    std.debug.print("Number of elements in solution (after cleanup): {d}\n", .{solution.items.len});

    if (_memoPairTable) |*t| {
        for (t.keys()) |k| if (t.get(k)) |v| v.deinit();
        t.deinit();
    }

    if (_memoQuartetTable) |*t| {
        for (t.keys()) |k| if (t.get(k)) |v| v.deinit();
        t.deinit();
    }

    {
        const file = try std.fs.cwd().createFile("output.csv", .{});
        defer file.close();

        for (solution.items) |s| {
            try file.writeAll(s[0][0]);
            try file.writeAll(",");
            try file.writeAll(s[0][1]);
            try file.writeAll(",");
            try file.writeAll(s[0][2]);
            try file.writeAll(",");
            try file.writeAll(s[0][3]);
            try file.writeAll(",");
            try file.writeAll(s[0][4]);
            try file.writeAll("\n");
        }
    }
}
