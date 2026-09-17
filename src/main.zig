const std = @import("std");
const Io = std.Io;

const pcre = @import("zig_pcre");

pub fn main(init: std.process.Init) !void
{
    _ = init;

    var dns_regex = try pcre.Regex.init(
        \\^(?:(?!-)[A-Za-z0-9-]{1,63}(?<!-)\.)+[A-Za-z]{2,}$
    );
    defer dns_regex.deinit();

    const valid_domains: []const []const u8 = &.{
        "example.com",
        "sub.example.co.uk",
        "dev.api.v1.domain.org",
        "my-site.com",
        "sub-domain.example-app.io",
        "123domain.com",
        "site2026.net",
        "360.agency",
        "brand.tech",
        "company.solutions",
        "app.ai",
        "data.xyz",
    };

    const invalid_domains: []const []const u8 = &.{
        "-example.com",
        "example-.com",
        "example.-com",
        "example..com",
        ".example.com",
        "example.com.",
        "ex_ample.com",
        "exam ple.com",
        "ex$ample.com",
        "example",
        ".com",
        "a123456789b123456789c123456789d123456789e123456789f123456789g1234.com",
        "https://example.com",
        "example.com/path",
        "example.com:8080",
        "admin@example.com",
    };

    for (valid_domains) |valid_domain| {
        const is_match = dns_regex.is_match(valid_domain);
        if (is_match) {
            std.debug.print("{s} matching\n", .{valid_domain});
        } else {
            std.debug.print("Error while matching valid domain {s}\n", .{valid_domain});
            return error.ValidDomainsUnsuccesfullMatching;
        }
    }

    for (invalid_domains) |invalid_domain| {
        const is_match = dns_regex.is_match(invalid_domain);
        if (!is_match) {
            std.debug.print("{s} success for testing non matching\n", .{invalid_domain});
        } else {
            std.debug.print("Error while matching invalid domain {s}\n", .{invalid_domain});
            return error.InValidDomainsUnsuccesfullMatching;
        }
    }
}

