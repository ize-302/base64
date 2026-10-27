const std = @import("std");
const encoder = @import("./encoder.zig");
const decoder = @import("./decoder.zig");

pub fn main(init: std.process.Init) !void {
    // encode
    const text = "Ma";

    // encode text
    const encoded = try encoder.Encode(init.gpa, text);
    defer init.gpa.free(encoded);
    std.debug.print("{s}\n", .{encoded});

    // decode the encoded text
    const decoded = try decoder.Decode(init.gpa, encoded);
    defer init.gpa.free(decoded);
    std.debug.print("{s}\n", .{decoded});
}
