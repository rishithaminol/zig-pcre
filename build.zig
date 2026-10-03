const std = @import("std");
const builtin = @import("builtin");

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
    const make_args = &.{
        "make",
        "libs",
        b.fmt("TARGET_TRIPLE={s}", .{target_triple}),
        b.fmt("BUILD_TYPE={s}", .{cmake_build_type}),
        b.fmt("EXTRA_FLAGS={s}", .{cflags}),
        b.fmt("ZIG_CC=zig cc -target {s} {s}", .{ target_triple, cflags }),
        b.fmt("ZIG_CXX=zig c++ -target {s} {s}", .{ target_triple, cflags }),
    };
    const make_pcre = b.addSystemCommand(make_args);
    make_pcre.setCwd(b.path("."));

    const pcre_headers = "libs/pcre2/build/interface";
    const pcrec = b.addTranslateC(.{
        .root_source_file = b.path("src/zig_pcre.h"),
        .target = target,
        .optimize = optimize,
    });
    pcrec.addIncludePath(b.path(pcre_headers));

    // This section has to be added ZLS server returns error.InvalidBuildConfig
    // because of execution of make_pcre dependency. Because of that a logic implemented
    // if (not exist directory(pcre_headers)) {
    //   add make_pcre as a step
    // }
    // All other builds does not call make_pcre step again in this block.
    switch(builtin.zig_version.minor) {
        16 => {
            _ = b.build_root.handle.openDir(b.graph.io, pcre_headers, .{}) catch |err| {
                if (err == error.FileNotFound) {
                    pcrec.step.dependOn(&make_pcre.step);
                }
            };
        },
        17 => {
            _ = b.root.openDir(b.graph.io, pcre_headers, .{}) catch |err| {
                if (err == error.FileNotFound) {
                    pcrec.step.dependOn(&make_pcre.step);
                }
            };
        },
        else => {}
    }


    const mod = b.addModule("zig_pcre", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .imports = &.{
            .{ .name = "pcrec", .module = pcrec.createModule() }
        }
    });
    mod.addLibraryPath(b.path("libs/pcre2/build"));
    mod.linkSystemLibrary("pcre2-8", .{
        .preferred_link_mode = .static,
    });


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


    // =============================[Testing]==============================
    // We should define the step identifier before configuring the step
    const test_step = b.step("test", "Run unit tests");
    const exe_unit_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .link_libc = true,
            .imports = &.{
                .{ .name = "zig_pcre", .module = mod },
            },
        }),
        .name = "zig_pcre_test"
    });

    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);
    test_step.dependOn(&run_exe_unit_tests.step);
}
