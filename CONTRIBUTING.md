# Development procedure

Clone this repository with submodules recursively.

```bash
zig build -Dtarget=x86_64-linux-musl

# zig build clean will be added in future. Until then use following command for cleaning
rm -rf zig-out/ .zig-cache/ libs/pcre2/build
```
