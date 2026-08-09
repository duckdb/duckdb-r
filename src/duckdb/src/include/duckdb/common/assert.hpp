//===----------------------------------------------------------------------===//
//                         DuckDB
//
// duckdb/common/assert.hpp
//
//
//===----------------------------------------------------------------------===//

#include "duckdb/common/winapi.hpp"

#pragma once

// clang-format off
#if ( \
    /* Not a debug build */ \
    !defined(DEBUG) && \
    /* FORCE_ASSERT is not set (enables assertions even on release mode when set to true) */ \
    !defined(DUCKDB_FORCE_ASSERT) && \
    /* The project is not compiled for Microsoft Visual Studio */ \
    !defined(__MVS__) \
)
// clang-format on

//! On most builds, NDEBUG is defined, turning the assert call into a NO-OP
//! Only the 'else' condition is supposed to check the assertions
#include <assert.h>
//! Unlike assert(), which discards its operand unparsed, this keeps the
//! condition named -- so a binding or helper that exists only for an assert is
//! still "used" in a release build -- and still type-checks it as a condition,
//! without evaluating anything. The `? 1 : 0` is load-bearing twice: it makes a
//! bit-field operand an rvalue, which sizeof cannot take directly, and it keeps
//! a comma operator out of the expansion, which GCC reports under -Wall.
#define D_ASSERT(condition) ((void)sizeof((condition) ? 1 : 0))
namespace duckdb {
DUCKDB_API void DuckDBAssertInternal(bool condition, const char *condition_name, const char *file, int linenr);
}

#else
namespace duckdb {
DUCKDB_API void DuckDBAssertInternal(bool condition, const char *condition_name, const char *file, int linenr);
}

#define D_ASSERT(condition) duckdb::DuckDBAssertInternal(bool(condition), #condition, __FILE__, __LINE__)
#define D_ASSERT_IS_ENABLED

#endif

//! Force assertion implementation, which always asserts whatever build type is used.
#define ALWAYS_ASSERT(condition) duckdb::DuckDBAssertInternal(bool(condition), #condition, __FILE__, __LINE__)
