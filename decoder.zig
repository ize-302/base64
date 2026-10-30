const std = @import("std");

const alphabet =
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

const ParseError = error{ InvalidCharacter, Overflow, OutOfMemory };

pub fn Decode(gpa: std.mem.Allocator, text: []const u8) ParseError![]u8 {
    var padding_count: usize = 0;

    for (text) |byte| {
        if (byte == '=' and (text[text.len - 1] != '=')) return error.InvalidCharacter;
    }

    padding_count = std.mem.countScalar(u8, text, '=');
    if (padding_count > 2) return error.InvalidCharacter;

    padding_count = 0; // reset
    if (text.len % 4 != 0) {
        return error.InvalidCharacter;
    } else if (text.len > 0) {
        if (text[text.len - 2] == '=') {
            padding_count = 2;
        } else if (text[text.len - 1] == '=' and text[text.len - 2] != '=') {
            padding_count = 1;
        }
    }

    // allocate the output buffer with its final size upfront
    const out = try gpa.alloc(u8, ((text.len / 4) * 3) - padding_count);
    errdefer gpa.free(out);

    var bit_pattern: std.ArrayList(u1) = .empty;
    defer bit_pattern.deinit(gpa);

    for (text, 0..) |byte, o| {
        _ = o;
        if (byte != '=') {
            const byte_index = std.mem.findScalar(u8, alphabet, byte) orelse return error.InvalidCharacter;
            var bits: [6]u1 = undefined;
            for (&bits, 0..) |*bit, i| bit.* = @truncate(byte_index >> @intCast(5 - i));
            try bit_pattern.appendSlice(gpa, &bits);
        }
    }

    // - split into groups of 8
    var counter: usize = 0;
    for (0..(bit_pattern.items.len / 8)) |o| {
        const end = counter + 8;
        const bits: []u1 = bit_pattern.items[counter..end];

        var buf: [8]u8 = undefined;
        for (bits, 0..) |b, i| buf[i] = '0' + @as(u8, b);

        const bits_str: []const u8 = &buf;

        counter = counter + 8;

        // binary string to decimal
        const bits_str_to_dec = try std.fmt.parseInt(u8, bits_str, 2);
        out[o] = bits_str_to_dec;
    }

    return out;
}
