const std = @import("std");
const decoder = @import("./decoder.zig");

fn expectDecoded(text: []const u8, expected: []const u8) !void {
    const gpa = std.testing.allocator;

    const result = try decoder.Decode(gpa, text);
    defer gpa.free(result);

    try std.testing.expectEqualStrings(expected, result);
}

// passes if Decode returns any error; frees the result if it unexpectedly succeeds
fn expectDecodeError(text: []const u8) !void {
    const gpa = std.testing.allocator;

    if (decoder.Decode(gpa, text)) |result| {
        const r = result;
        defer gpa.free(r);
        return error.TestExpectedError;
    } else |_| {}
}

test "testing decoding empty string" {
    try expectDecoded("", "");
}

test "testing decoding simple words" {
    try expectDecoded("TWFu", "Man");
    try expectDecoded("TWE=", "Ma");
    try expectDecoded("TQ==", "M");
}

// test vectors from RFC 4648 section 10
test "testing decoding RFC 4648 vectors" {
    try expectDecoded("Zg==", "f");
    try expectDecoded("Zm8=", "fo");
    try expectDecoded("Zm9v", "foo");
    try expectDecoded("Zm9vYg==", "foob");
    try expectDecoded("Zm9vYmE=", "fooba");
    try expectDecoded("Zm9vYmFy", "foobar");
}

test "testing decoding sentence with punctuation" {
    try expectDecoded("SGVsbG8sIFdvcmxkIQ==", "Hello, World!");
    try expectDecoded("YW55IGNhcm5hbCBwbGVhc3VyZS4=", "any carnal pleasure.");
}

test "testing decoding input containing '+' and '/'" {
    try expectDecoded("Pz4/", "?>?");
    try expectDecoded("fn5+", "~~~");
}

test "testing decoding non-ASCII UTF-8" {
    try expectDecoded("w6k=", "é");
    try expectDecoded("4oKs", "€");
    try expectDecoded("5pel5pys", "日本");
    try expectDecoded("8J+YgA==", "😀");
}

test "testing decoding arbitrary bytes" {
    try expectDecoded("+/8=", "\xfb\xff");
    try expectDecoded("AA==", "\x00");
}

test "testing decoding invalid character" {
    try expectDecodeError("TW!u");
    try expectDecodeError("TW u");
}

test "testing decoding invalid length" {
    try expectDecodeError("TWF");
    try expectDecodeError("T");
}

test "testing decoding misplaced padding" {
    try expectDecodeError("=TWF");
    try expectDecodeError("TW=u");
    try expectDecodeError("T===");
}
