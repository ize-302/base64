const std = @import("std");

// TODO: complete implementation
pub fn Decode(gpa: std.mem.Allocator, text: []const u8) ![]u8 {
    const decoded_result: std.ArrayList(u8) = .empty;
    _ = text;
    _ = gpa;
    return decoded_result.items;
}
