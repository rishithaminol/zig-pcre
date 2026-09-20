const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const target_triple = target.result.zigTriple(b.allocator) catch @panic("OOM");

    // Map Zig optimize option to CMake build type and CFLAGS
    const cmake_build_type = switch (optimize) {
        .Debug => "Debug",
        .ReleaseSmall => "MinSizeRel",
        .ReleaseFast => "Release",
        .ReleaseSafe => "RelWithDebInfo",
    };

    const cflags = switch (optimize) {
        .Debug => "-O0 -g",
        .ReleaseSmall => "-Os",
        .ReleaseFast => "-O3",
        .ReleaseSafe => "-O2 -g",
    };

    // Pass target triple, build mode, and Zig C compiler wrappers to Make
    // later usage of make_pcre.step will trigger this build
    const make_pcre = b.addSystemCommand(&.{
        "make",
        "libs",
        b.fmt("TARGET_TRIPLE={s}", .{target_triple}),
        b.fmt("BUILD_TYPE={s}", .{cmake_build_type}),
        b.fmt("EXTRA_FLAGS={s}", .{cflags}),
        b.fmt("ZIG_CC=zig cc -target {s} {s}", .{ target_triple, cflags }),
        b.fmt("ZIG_CXX=zig c++ -target {s} {s}", .{ target_triple, cflags }),
    });
    make_pcre.setCwd(b.path("."));

    const pcrec = b.addTranslateC(.{
        .root_source_file = b.path("src/c/zig_pcre.h"),
        .target = target,
        .optimize = optimize,
    });
    pcrec.addIncludePath(b.path("libs/pcre2/build/interface"));
    pcrec.addIncludePath(b.path("src/c"));
    pcrec.step.dependOn(&make_pcre.step);

    const mod = b.addModule("zig_pcre", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .imports = &.{
            .{ .name = "pcrec", .module = pcrec.createModule() }
        }
    });

    // Point to directory containing libpcre2-8.a
    mod.addLibraryPath(b.path("libs/pcre2/build"));

    // Statically link pcre2-8 instead of treating the .a file as a raw object
    mod.linkSystemLibrary("pcre2-8", .{
        .preferred_link_mode = .static,
    });



    const lib = b.addLibrary(.{
        .name = "zig_pcre",
        .linkage = .static,
        .root_module = mod,
    });
    lib.linker_allow_shlib_undefined = true;

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
}
