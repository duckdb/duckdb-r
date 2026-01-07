#pragma once

// C++ Version Detection for cpp4r
// Provides feature detection macros for various C++ standards

// Detect C++14
#if __cplusplus >= 201402L
#define CPP4R_HAS_CXX14 1
#else
#define CPP4R_HAS_CXX14 0
#endif

// Detect C++17
#if __cplusplus >= 201703L
#define CPP4R_HAS_CXX17 1
#else
#define CPP4R_HAS_CXX17 0
#endif

// Detect C++20
#if __cplusplus >= 202002L
#define CPP4R_HAS_CXX20 1
#else
#define CPP4R_HAS_CXX20 0
#endif

// Detect C++23
#if __cplusplus >= 202302L
#define CPP4R_HAS_CXX23 1
#else
#define CPP4R_HAS_CXX23 0
#endif

// Feature-specific detection

// C++14 features
#if CPP4R_HAS_CXX14
#define CPP4R_HAS_VARIABLE_TEMPLATES 1
#define CPP4R_HAS_GENERIC_LAMBDAS 1
#define CPP4R_HAS_RELAXED_CONSTEXPR 1
#else
#define CPP4R_HAS_VARIABLE_TEMPLATES 0
#define CPP4R_HAS_GENERIC_LAMBDAS 0
#define CPP4R_HAS_RELAXED_CONSTEXPR 0
#endif

// C++17 features
#if CPP4R_HAS_CXX17
#define CPP4R_HAS_IF_CONSTEXPR 1
#define CPP4R_HAS_INLINE_VARIABLES 1
#define CPP4R_HAS_STRUCTURED_BINDINGS 1
#define CPP4R_HAS_FOLD_EXPRESSIONS 1
#define CPP4R_HAS_STD_OPTIONAL 1
#else
#define CPP4R_HAS_IF_CONSTEXPR 0
#define CPP4R_HAS_INLINE_VARIABLES 0
#define CPP4R_HAS_STRUCTURED_BINDINGS 0
#define CPP4R_HAS_FOLD_EXPRESSIONS 0
#define CPP4R_HAS_STD_OPTIONAL 0
#endif

// C++20 features
#if CPP4R_HAS_CXX20
#define CPP4R_HAS_CONCEPTS 1
#define CPP4R_HAS_RANGES 1
#define CPP4R_HAS_CONSTEVAL 1
#define CPP4R_HAS_STD_SPAN 1
#else
#define CPP4R_HAS_CONCEPTS 0
#define CPP4R_HAS_RANGES 0
#define CPP4R_HAS_CONSTEVAL 0
#define CPP4R_HAS_STD_SPAN 0
#endif

// C++23 features
#if CPP4R_HAS_CXX23
#define CPP4R_HAS_STD_EXPECTED 1
#define CPP4R_HAS_MULTIDIMENSIONAL_SUBSCRIPT 1
#define CPP4R_HAS_IF_CONSTEVAL 1
#else
#define CPP4R_HAS_STD_EXPECTED 0
#define CPP4R_HAS_MULTIDIMENSIONAL_SUBSCRIPT 0
#define CPP4R_HAS_IF_CONSTEVAL 0
#endif

// Compiler-specific optimizations
#ifdef __GNUC__
#define CPP4R_HAS_BUILTIN_EXPECT 1
#else
#define CPP4R_HAS_BUILTIN_EXPECT 0
#endif

// Utility macros for conditional compilation
#if CPP4R_HAS_IF_CONSTEXPR
#define CPP4R_IF_CONSTEXPR if constexpr
#else
#define CPP4R_IF_CONSTEXPR if
#endif

#if CPP4R_HAS_CXX17
#define CPP4R_NODISCARD [[nodiscard]]
#else
#define CPP4R_NODISCARD
#endif

// CPP4R_LIKELY and CPP4R_UNLIKELY: branch prediction hints
// These remain as function-like macros for consistency across all C++ versions
// In C++20+, the compiler is smart enough to optimize these patterns anyway
#if defined(__GNUC__) || defined(__clang__)
#define CPP4R_LIKELY(x) __builtin_expect(!!(x), 1)
#define CPP4R_UNLIKELY(x) __builtin_expect(!!(x), 0)
#else
#define CPP4R_LIKELY(x) (x)
#define CPP4R_UNLIKELY(x) (x)
#endif

// CPP4R_RESTRICT: pointer aliasing hints for better optimization
#if defined(__GNUC__) || defined(__clang__)
#define CPP4R_RESTRICT __restrict__
#elif defined(_MSC_VER)
#define CPP4R_RESTRICT __restrict
#else
#define CPP4R_RESTRICT
#endif

// CPP4R_ALWAYS_INLINE: force inlining of hot path functions
// CPP4R_NOINLINE: prevent inlining of cold path functions
#if CPP4R_HAS_CXX17 && (defined(__GNUC__) || defined(__clang__))
#define CPP4R_ALWAYS_INLINE [[gnu::always_inline]] inline
#define CPP4R_NOINLINE [[gnu::noinline]]
#elif defined(__GNUC__) || defined(__clang__)
#define CPP4R_ALWAYS_INLINE __attribute__((always_inline)) inline
#define CPP4R_NOINLINE __attribute__((noinline))
#elif defined(_MSC_VER)
#define CPP4R_ALWAYS_INLINE __forceinline
#define CPP4R_NOINLINE __declspec(noinline)
#else
#define CPP4R_ALWAYS_INLINE inline
#define CPP4R_NOINLINE
#endif

// CPP4R_HOT: mark frequently executed functions for better optimization
// CPP4R_COLD: mark rarely executed functions (errors, initialization)
#if defined(__GNUC__) || defined(__clang__)
#define CPP4R_HOT __attribute__((hot))
#define CPP4R_COLD __attribute__((cold))
#else
#define CPP4R_HOT
#define CPP4R_COLD
#endif

// CPP4R_ASSUME_ALIGNED: hint to compiler about pointer alignment
// Useful for SIMD optimization when working with R vector data
#if defined(__GNUC__) || defined(__clang__)
#define CPP4R_ASSUME_ALIGNED(ptr, alignment) __builtin_assume_aligned(ptr, alignment)
#else
#define CPP4R_ASSUME_ALIGNED(ptr, alignment) (ptr)
#endif

// CPP4R_PREFETCH: prefetch data to cache for better performance
#if defined(__GNUC__) || defined(__clang__)
#define CPP4R_PREFETCH(addr) __builtin_prefetch(addr)
#define CPP4R_PREFETCH_WRITE(addr) __builtin_prefetch(addr, 1)
#else
#define CPP4R_PREFETCH(addr) ((void)0)
#define CPP4R_PREFETCH_WRITE(addr) ((void)0)
#endif

// CPP4R_ASSUME: hint to compiler about invariants (C++23 std::assume)
// Helps compiler optimize by asserting conditions that are always true
#if CPP4R_HAS_CXX23 && defined(__cpp_lib_unreachable) && __cpp_lib_unreachable >= 202202L
#include <utility>
#define CPP4R_ASSUME(expr)           \
  do {                               \
    if (!(expr)) std::unreachable(); \
  } while (0)
#elif defined(__clang__)
#define CPP4R_ASSUME(expr) __builtin_assume(expr)
#elif defined(__GNUC__) && __GNUC__ >= 13
#define CPP4R_ASSUME(expr)                \
  do {                                    \
    if (!(expr)) __builtin_unreachable(); \
  } while (0)
#elif defined(_MSC_VER)
#define CPP4R_ASSUME(expr) __assume(expr)
#else
#define CPP4R_ASSUME(expr) ((void)0)
#endif

// CPP4R_UNROLL: hint to compiler to unroll loops
// C++20 added #pragma unroll, but compiler support varies
#if defined(__clang__)
#define CPP4R_UNROLL_LOOP _Pragma("clang loop unroll(full)")
#define CPP4R_UNROLL_N(n) _Pragma(CPP4R_STRINGIFY(clang loop unroll_count(n)))
#elif defined(__GNUC__) && __GNUC__ >= 8
#define CPP4R_UNROLL_LOOP _Pragma("GCC unroll 8")
#define CPP4R_UNROLL_N(n) _Pragma(CPP4R_STRINGIFY(GCC unroll n))
#else
#define CPP4R_UNROLL_LOOP
#define CPP4R_UNROLL_N(n)
#endif

#define CPP4R_STRINGIFY(x) CPP4R_STRINGIFY_IMPL(x)
#define CPP4R_STRINGIFY_IMPL(x) #x

// CPP4R_VECTORIZE: hint to compiler to vectorize loops (SIMD)
#if defined(__clang__)
#define CPP4R_VECTORIZE _Pragma("clang loop vectorize(enable)")
#elif defined(__GNUC__) && __GNUC__ >= 5
#define CPP4R_VECTORIZE _Pragma("GCC ivdep")
#elif defined(_MSC_VER)
#define CPP4R_VECTORIZE __pragma(loop(ivdep))
#else
#define CPP4R_VECTORIZE
#endif
