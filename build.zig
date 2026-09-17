const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const target_triple = target.result.zigTriple(b.allocator) catch @panic("OOM");

    const make_pcre = b.addSystemCommand(&.{
        "make",
        "libs",
        b.fmt("TARGET_TRIPLE={s}", .{target_triple}),
    });

    const mod = b.addModule("zig_pcre", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });

    mod.addObjectFile(b.path("libs/pcre2/build/libpcre2-8.a"));
    mod.addIncludePath(b.path("libs/pcre2/build/interface"));
    mod.addIncludePath(b.path("src/c"));

    const lib = b.addLibrary(.{
        .name = "zig_pcre",
        .linkage = .static,
        .root_module = mod,
    });

    lib.step.dependOn(&make_pcre.step);
    b.installArtifact(lib);

    const exe = b.addExecutable(.{
        .name = "zig_pcre_runner",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .link_libc = true,
            .imports = &.{
                .{ .name = "zig_pcre", .module = mod },
            },
        }),
    });

    exe.step.dependOn(&make_pcre.step);
    b.installArtifact(exe);

    const run_step = b.step("run", "Run the app");
    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
}
