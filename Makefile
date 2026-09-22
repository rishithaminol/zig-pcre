TARGET_TRIPLE ?= x86_64-linux-musl
BUILD_TYPE    ?= Debug
EXTRA_FLAGS ?=

ZIG_CC        := $(CURDIR)/.toolchain/zig-cc -target $(TARGET_TRIPLE) $(EXTRA_FLAGS)
ZIG_CXX       := $(CURDIR)/.toolchain/zig-c++ -target $(TARGET_TRIPLE) $(EXTRA_FLAGS)

BUILD_DIR := libs/pcre2/build


.PHONY: libs compile_commands.json libpcre2

libs: libpcre2

libpcre2:
	@mkdir -p $(BUILD_DIR)
	CC="$(ZIG_CC)" CXX="$(ZIG_CXX)" cmake -S libs/pcre2 -B $(BUILD_DIR) \
		-DCMAKE_BUILD_TYPE=$(BUILD_TYPE) \
		-DCMAKE_C_FLAGS="$(EXTRA_FLAGS)" \
		-DPCRE2_STATIC_PIC=ON \
		-DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
		-DCMAKE_SYSROOT="/" \
		-DPCRE2_SUPPORT_LIBZ=OFF \
		-DPCRE2_SUPPORT_LIBREADLINE=OFF \
		-DPCRE2_SUPPORT_LIBBZ2=OFF \
		-DPCRE2_SUPPORT_LIBEDIT=OFF \
		-DPCRE2_BUILD_PCRE2GREP=OFF \
		-DPCRE2_BUILD_TESTS=OFF
	$(MAKE) -C $(BUILD_DIR) -j
	@# Symlink or copy interface files if generated in target build directory
	@cp -f $(BUILD_DIR)/pcre2.h libs/pcre2/build/interface/ 2>/dev/null || true


# Only for Kate editor to identify C references.
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
