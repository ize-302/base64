const std = @import("std");
const expect = std.testing.expect;
const encoder = @import("./encoder.zig");

fn expectEncoded(text: []const u8, expected: []const u8) !void {
    const gpa = std.testing.allocator;

    const result = try encoder.Encode(gpa, text);
    defer gpa.free(result);

    try std.testing.expectEqualStrings(expected, result);
}

test "testing encoding empty string" {
    try expectEncoded("", "");
}

test "testing encoding simple words" {
    try expectEncoded("Man", "TWFu");
    try expectEncoded("Ma", "TWE=");
    try expectEncoded("M", "TQ==");
}

// test vectors from RFC 4648 section 10
test "testing encoding RFC 4648 vectors" {
    try expectEncoded("f", "Zg==");
    try expectEncoded("fo", "Zm8=");
    try expectEncoded("foo", "Zm9v");
    try expectEncoded("foob", "Zm9vYg==");
    try expectEncoded("fooba", "Zm9vYmE=");
    try expectEncoded("foobar", "Zm9vYmFy");
}

test "testing encoding sentence with punctuation" {
    try expectEncoded("Hello, World!", "SGVsbG8sIFdvcmxkIQ==");
    try expectEncoded("any carnal pleasure.", "YW55IGNhcm5hbCBwbGVhc3VyZS4=");
}

test "testing encoding output containing '+' and '/'" {
    try expectEncoded("?>?", "Pz4/");
    try expectEncoded("~~~", "fn5+");
}

test "testing encoding digits and whitespace" {
    try expectEncoded("1234567890", "MTIzNDU2Nzg5MA==");
    try expectEncoded(" \t\n", "IAkK");
}

test "testing encoding non-ASCII UTF-8" {
    try expectEncoded("é", "w6k="); // 2 bytes: C3 A9
    try expectEncoded("€", "4oKs"); // 3 bytes: E2 82 AC
    try expectEncoded("日本", "5pel5pys"); // 6 bytes
    try expectEncoded("😀", "8J+YgA=="); // 4 bytes: F0 9F 98 80
}

test "testing encoding arbitrary bytes" {
    try expectEncoded("\xfb\xff", "+/8="); // invalid UTF-8
    try expectEncoded("\x00", "AA=="); // null byte
}
