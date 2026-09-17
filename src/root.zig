const std = @import("std");
const pcre = @cImport({
    @cInclude("zig_pcre.h");
});

pub const Regex = struct {
    code: *pcre.zig_pcre_code,

    pub fn init(pattern: [:0]const u8) !Regex {
        var error_number: c_int = 0;
        var error_offset: pcre.PCRE2_SIZE = 0;

        const compiled = pcre.zig_pcre2_compile(
            pattern.ptr,
            pcre.ZIG_PCRE2_ZERO_TERMINATED,
            0,
            &error_number,
            &error_offset,
            null,
        ) orelse return error.Pcre2CompilationFailed;

        return .{ .code = compiled };
    }

    pub fn deinit(self: *Regex) void {
        pcre.zig_pcre2_code_free(self.code);
    }

    pub fn is_match(self: Regex, subject: []const u8) bool {
        const match_data = pcre.zig_pcre2_match_data_create_from_pattern(self.code, null) orelse return false;
        defer pcre.zig_pcre2_match_data_free(match_data);

        const rc = pcre.zig_pcre2_match(
            self.code,
            subject.ptr,
            subject.len,
            0,
            0,
            match_data,
            null,
        );

        return rc >= 0;
    }
};
