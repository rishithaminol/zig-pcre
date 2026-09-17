#ifndef ZIG_PCRE_H
#define ZIG_PCRE_H

#define PCRE2_CODE_UNIT_WIDTH 8
#include <pcre2.h>

typedef pcre2_code zig_pcre_code;
typedef pcre2_match_data zig_pcre_match_data;
size_t ZIG_PCRE2_ZERO_TERMINATED = (~(size_t)0);

// Wrap macro functions into static inline functions
static inline zig_pcre_code* zig_pcre2_compile(
    PCRE2_SPTR8 pattern,
    size_t length,
    uint32_t options,
    int *errornumber,
    size_t *erroroffset,
    pcre2_compile_context_8 *ccontext)
{
    return pcre2_compile_8(pattern, length, options, errornumber, erroroffset, ccontext);
}

static inline void zig_pcre2_code_free(zig_pcre_code *code) {
    pcre2_code_free(code);
}

static inline zig_pcre_match_data* zig_pcre2_match_data_create_from_pattern(
    const zig_pcre_code *code,
    pcre2_general_context_8 *gcontext)
{
    // return pcre2_match_data_create_from_pattern_8(code, gcontext);
    return pcre2_match_data_create_from_pattern(code, gcontext);
}

static inline void zig_pcre2_match_data_free(zig_pcre_match_data *match_data) {
    // pcre2_match_data_free_8(match_data);
    pcre2_match_data_free(match_data);
}

static inline int zig_pcre2_match(
    const zig_pcre_code *code,
    PCRE2_SPTR8 subject,
    size_t length,
    size_t startoffset,
    uint32_t options,
    zig_pcre_match_data *match_data,
    pcre2_match_context_8 *mcontext)
{
    return pcre2_match(code, subject, length, startoffset, options, match_data, mcontext);
}

#endif
