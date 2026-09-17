# Variable to inject extra common build options to both CC and CXX
# Example usage: make EXTRA_FLAGS="-O3 -march=x86-64-v3"
EXTRA_FLAGS ?=

# Toolchain definitions targeting x86_64 Linux with musl libc via Zig
TARGET_TRIPLE ?= x86_64-linux-musl
BUILD_TYPE    ?= Debug
ZIG_CC        := $(CURDIR)/.toolchain/zig-cc -target $(TARGET_TRIPLE) $(EXTRA_FLAGS)
ZIG_CXX       := $(CURDIR)/.toolchain/zig-c++ -target $(TARGET_TRIPLE) $(EXTRA_FLAGS)

# Common environment variables passed to CMake configurations
CMAKE_ENV     := CC="$(ZIG_CC)" CXX="$(ZIG_CXX)" CMAKE_BUILD_TYPE="$(BUILD_TYPE)"

.PHONY: all libs compile_commands.json libpcre2

# --- Primary Targets ---
all: libs compile_commands.json

# Dependant libraries
libs: libpcre2

# --- Compilation Database Generation ---

# Merges all sub-project JSON files into a master database at the project root for clangd
compile_commands.json:
	@echo "==> Generating compilation database entries for application source..."
	@find src/c -name "*.c" 2>/dev/null | jq -R -s -c \
		--arg dir "$(CURDIR)" \
		--arg cmd "$(ZIG_CC) -Ilibs/pcre2 -Ilibs/pcre2/build/interface" \
		'split("\n") | map(select(length > 0) | {directory: $$dir, command: ($$cmd + " -c " + .), file: .})' > .app_commands.json
	@echo "==> Merging all compilation databases for clangd..."
	@jq -s 'add' \
		.app_commands.json \
		libs/pcre2/build/compile_commands.json > compile_commands.json 2>/dev/null || echo "[]" > compile_commands.json
	@rm -f .app_commands.json

# --- Sub-project Targets ---
libpcre2:
	@echo "Building libpcre2 for target $(TARGET_TRIPLE)....."
	$(CMAKE_ENV) cmake -S libs/pcre2 -B libs/pcre2/build \
		-DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
		-DPCRE2_STATIC_PIC=ON
	$(MAKE) -C libs/pcre2/build -j
