# How to use `zig-pcre` module

    zig fetch --save git+http://<the repourl>/zig-pcre.git
    
Configure `build.zig` with the following configurations.

    const zig_pcre_dep = b.dependency("zig_pcre", .{
        .target = target,
        .optimize = optimize,
    });

    // Fetch the "zig_pcre" module exposed by zig-pcre's build.zig
    const pcre_mod = zig_pcre_dep.module("zig_pcre");

    // Fetch the artifact (This brings lib.step and make_pcre into parent's step graph)
    const pcre_lib = zig_pcre_dep.artifact("zig_pcre");

    // Rest of your build.zig code
    // exe.root_module

    // Add module import and link the artifact step
    exe.root_module.addImport("zig_pcre", pcre_mod);
    exe.root_module.linkLibrary(pcre_lib);

Example code within your `main.zig` file

    var dns_regex = try pcre.Regex.init(
        \\^(?:(?!-)[A-Za-z0-9-]{1,63}(?<!-)\.)+[A-Za-z]{2,}$
    );
    defer dns_regex.deinit();

    const is_match = dns_regex.is_match("ziglang.org");
    if(is_match) {
        std.debug.print("There is a match\n", .{});
    }

Build commands

    # Debug
    zig build -Dtarget=x86_64-linux-musl

    # Release
    zig build -Dtarget=x86_64-linux-musl -Doptimize=ReleaseSmall
    

# Development procedure

libpcre2 is not imported as a `git` submodule. It is directly embedded into the source code. And the current stable working branch is `pcre2-10.48`.

This is the procedure each time we recive a new `libpcre2` update.

    rm -rf libs/pcre2
    git clone 'https://github.com/PCRE2Project/pcre2.git' libs/pcre2
    cd libs/pcre2
    git checkout <new upcoming stable tag>
    rm -rf .git

After this step the `libs/pcre2` should not be touched.

    zig build -Dtarget=x86_64-linux-musl

    # zig build clean will be added in future. Until then use following command for cleaning
    rm -rf zig-out/ .zig-cache/ libs/pcre2/build


