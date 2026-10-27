const std = @import("std");

const alphabet =
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

pub fn Encode(gpa: std.mem.Allocator, text: []const u8) ![]u8 {
    // allocate the output buffer with its final size upfront
    const out = try gpa.alloc(u8, 4 * ((text.len + 2) / 3));
    errdefer gpa.free(out);

    var bit_pattern: std.ArrayList(u1) = .empty;
    defer bit_pattern.deinit(gpa);

    // convert each byte to binary
    for (text) |byte| {
        var bits: [8]u1 = undefined;
        for (&bits, 0..) |*bit, i| bit.* = @truncate(byte >> @intCast(7 - i));

        try bit_pattern.appendSlice(gpa, &bits);
    }

    // pad bit_pattern with 0s. Needs padding because:
    // - Base64 takes input 3 bytes (24 bits) at a time
    // - It splits each group into 4 chunks of 6 bits. Each chunk represents one character
    // - Input length is not always a multiple of 3. The last group can have 1 or 2 bytes
    const bits_remaining = bit_pattern.items.len % 6;
    if (bits_remaining > 0) {
        for (0..(6 - bits_remaining)) |_| try bit_pattern.append(gpa, 0);
    }

    // split bits into chunks of 6 bits
    var counter: usize = 0;
    for (0..(bit_pattern.items.len / 6)) |o| {
        const end = counter + 6;
        const bits: []u1 = bit_pattern.items[counter..end];

        var buf: [6]u8 = undefined;
        for (bits, 0..) |b, i| buf[i] = '0' + @as(u8, b);

        const bits_str: []const u8 = &buf;

        counter = counter + 6;

        // binary string to decimal
        const bits_str_to_dec = try std.fmt.parseInt(u8, bits_str, 2);
        out[o] = alphabet[bits_str_to_dec];
    }

    const byte_count = bit_pattern.items.len / 8;
    const leftover = byte_count % 3;
    if (leftover == 1) {
        out[out.len - 2] = '=';
        out[out.len - 1] = '=';
    }
    if (leftover == 2) out[out.len - 1] = '=';

    return out;
}
