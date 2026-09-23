# Zig-PCRE

**Zig-PCRE** brings stable, high-performance PCRE2 regular expression support to the Zig ecosystem.

By leveraging Zig's native C compilation capabilities to build `libpcre2` directly, `zig-pcre` delivers a self-contained dependency with zero friction and long-term resilience against breaking changes across Zig toolchain versions.

### Key Features

* **Cross-Version Stability:** Designed to shield your project from build or runtime breakage as the Zig language evolves.
* **Zero System Dependencies:** Compiles `libpcre2` directly using Zig's C compiler; no external system packages or pre-installed dynamic libraries required.
* **Native C Integration:** Built from the ground up embracing Zig's philosophy of treating C as **"The First Class Citizen"**.
* **Multi-Platform:** Tier-1 support for **Linux** and **FreeBSD**, with early experimental support for **Windows**.

> [!NOTE]
> We have no activity on github.com. It's just a mirror. All activity is within Codeberg.org [zig-pcre](https://codeberg.org/rishithaminol/zig-pcre.git)

# LICENSE

`zig-pcre` is licensed under the [BSD 3-Clause License](https://opensource.org/license/bsd-3-clause).

This project includes PCRE2 as a Git submodule under `libs/pcre2/`, which is licensed under the [PCRE2 License](https://github.com/PCRE2Project/pcre2/blob/main/LICENCE.md).

# How to use `zig-pcre` module

At the moment of development of this library `zig fetch` have some issues with `.tar.gz` file download from codeberg.org. In that case we suggest you to download `zig-pcre-vx.x.x.tar.gz` package and use zig fetch to include within your project. The zig-pcre will not compile if it fetched as a git source because of the existance of `libpcre2` as a git submodule. `zig fetch` does not support Git recursive clone of submodules.

    zig fetch --save https://<repository URI>/zig-pcre/releases/download/v0.1.6/zig-pcre-v0.1.7.tar.gz

Configure `build.zig` of your zig program with the following configurations.

```zig
const zig_pcre_dep = b.dependency("zig_pcre", .{
    .target = target,
    .optimize = optimize,
});

// Fetch the "zig_pcre" module exposed by zig-pcre's build.zig
const pcre_mod = zig_pcre_dep.module("zig_pcre");
const pcre_lib = zig_pcre_dep.artifact("zig_pcre");

// Rest of your build.zig code
// whatever_your_module

// Add module import and link the artifact step
whatever_your_module.addImport("zig_pcre", pcre_mod);
whatever_your_module.linkLibrary(pcre_lib);
```

Example code within your `main.zig` file

```zig
var dns_regex = try pcre.Regex.init(
    \\^(?:(?!-)[A-Za-z0-9-]{1,63}(?<!-)\.)+[A-Za-z]{2,}$
);
defer dns_regex.deinit();

const is_match = dns_regex.is_match("ziglang.org");
if(is_match) {
    std.debug.print("There is a match\n", .{});
}
```

Build commands

```bash
# Debug
zig build -Dtarget=x86_64-linux-musl

# Release
zig build -Dtarget=x86_64-linux-musl -Doptimize=ReleaseSmall
```

# Zig support matrix

|                | v0.16.x             | v0.17.x              |
|----------------|---------------------|----------------------|
| zig-pcre-0.1.6 | :green_circle:      | :green_circle:       |
| zig-pcre-0.1.7 | :green_circle:      | :green_circle:       |

# Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md)
