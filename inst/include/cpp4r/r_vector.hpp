#pragma once

// Main r_vector header - includes all components

#include "cpp4r/r_vector_fwd.hpp"
#include "cpp4r/r_vector_impl.hpp"
#include "cpp4r/r_vector_writable_impl.hpp"

namespace cpp4r {

// Helper conversion functions

// Ensure that C is not constructible from SEXP, and neither C nor T is a std::string
template <typename C, typename T = typename std::decay<C>::type::value_type>
typename std::enable_if<
    !std::is_constructible<C, SEXP>::value &&
        !std::is_same<typename std::decay<C>::type, std::string>::value &&
        !std::is_same<typename std::decay<T>::type, std::string>::value,
    C>::type
as_cpp(SEXP from) {
  auto obj = cpp4r::r_vector<T>(from);
  return {obj.begin(), obj.end()};
}

namespace detail {
// SFINAE check for reserve method
template <typename T>
class has_reserve {
  template <typename C>
  static std::true_type test(decltype(std::declval<C>().reserve(0))*);
  template <typename C>
  static std::false_type test(...);

 public:
  static constexpr bool value = decltype(test<T>(nullptr))::value;
};

template <typename C>
typename std::enable_if<has_reserve<C>::value>::type try_reserve(C& c, size_t n) {
  c.reserve(n);
}

template <typename C>
typename std::enable_if<!has_reserve<C>::value>::type try_reserve(C&, size_t) {
  // No-op
}
}  // namespace detail

// TODO: could we make this generalize outside of std::string?
template <typename C, typename T = typename std::decay<C>::type::value_type>
// typename T = typename C::value_type>
is_vector_of_strings<C, T> as_cpp(SEXP from) {
  auto obj = cpp4r::r_vector<cpp4r::r_string>(from);
  typename std::decay<C>::type res;
  detail::try_reserve(res, obj.size());
  auto it = obj.begin();
  while (it != obj.end()) {
    r_string s = *it;
    res.emplace_back(static_cast<std::string>(s));
    ++it;
  }
  return res;
}

// Comparison operators

template <typename T>
bool operator==(const r_vector<T>& lhs, const r_vector<T>& rhs) noexcept {
  if (lhs.size() != rhs.size()) {
    return false;
  }

  auto lhs_it = lhs.begin();
  auto rhs_it = rhs.begin();

  auto end = lhs.end();
  while (lhs_it != end) {
    if (!(*lhs_it == *rhs_it)) {
      return false;
    }
    ++lhs_it;
    ++rhs_it;
  }
  return true;
}

// Utility: translate an R `names` STRSXP into a std::vector<std::string> once.
// This is intended for callers that perform many name lookups and want to avoid
// repeated calls to `Rf_translateCharUTF8(STRING_ELT(...))`.
inline std::vector<std::string> translate_names_to_vector(SEXP names) {
  std::vector<std::string> out;
  if (names == R_NilValue) return out;

  R_xlen_t n = Rf_xlength(names);
  out.reserve(static_cast<size_t>(n));
  for (R_xlen_t i = 0; i < n; ++i) {
    const char* s = Rf_translateCharUTF8(STRING_ELT(names, i));
    out.emplace_back(s ? s : "");
  }
  return out;
}

// Utility: find name position using a pre-translated vector of names. Returns
// -1 if not found. This is intentionally simple and avoids creating temporary
// r_string objects.
inline ptrdiff_t find_name_pos_cached(const std::vector<std::string>& names,
                                      const r_string& key) {
  for (ptrdiff_t i = 0; i < static_cast<ptrdiff_t>(names.size()); ++i) {
    if (names[i] == static_cast<std::string>(key)) return i;
  }
  return -1;
}

// Convenience wrappers to forward cached lookups to r_vector implementations.
template <typename T>
inline typename r_vector<T>::const_iterator find_cached(
    const r_vector<T>& v, const std::vector<std::string>& names_cache,
    const r_string& key) {
  return v.find_cached(names_cache, key);
}

template <typename T>
inline typename writable::r_vector<T>::iterator find_cached(
    const writable::r_vector<T>& v, const std::vector<std::string>& names_cache,
    const r_string& key) {
  return v.find_cached(names_cache, key);
}

template <typename T>
bool operator!=(const r_vector<T>& lhs, const r_vector<T>& rhs) noexcept {
  return !(lhs == rhs);
}

}  // namespace cpp4r
