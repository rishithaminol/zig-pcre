# How to use this zig module



# Development procedure

libpcre2 is not imported as a `git` submodule. It is directly embedded into the source code. And the current stable working branch is `pcre2-10.48`.

This is the procedure each time we recive a new `libpcre2` update.

    rm -rf libs/pcre2
    git clone 'https://github.com/PCRE2Project/pcre2.git' libs/pcre2
    cd libs/pcre2
    git checkout <new upcoming stable tag>
    rm -rf .git

And after this we should not touch the pcre2 codebase since we assume it as a static.

