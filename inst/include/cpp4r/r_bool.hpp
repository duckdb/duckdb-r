#pragma once

#include <limits>
#include <ostream>
#include <type_traits>

#include "R_ext/Boolean.h"
#include "cpp4r/R.hpp"
#include "cpp4r/as.hpp"
#include "cpp4r/protect.hpp"
#include "cpp4r/r_vector.hpp"
#include "cpp4r/sexp.hpp"

namespace cpp4r {

class r_bool {
 public:
  r_bool() noexcept = default;

  r_bool(SEXP data) {
    if (Rf_isLogical(data) && Rf_xlength(data) == 1) {
      value_ = static_cast<Rboolean>(LOGICAL_ELT(data, 0));
      return;
    }
    throw std::invalid_argument("Invalid r_bool value");
  }

  r_bool(bool value) noexcept : value_(value ? TRUE : FALSE) {}
  r_bool(Rboolean value) noexcept : value_(value) {}
  r_bool(int value) noexcept : value_(from_int(value)) {}

  operator bool() const noexcept { return value_ == TRUE; }
  operator int() const noexcept { return value_; }
  operator Rboolean() const noexcept { return value_ ? TRUE : FALSE; }

  bool operator==(r_bool rhs) const noexcept { return value_ == rhs.value_; }
  bool operator==(bool rhs) const noexcept { return operator==(r_bool(rhs)); }
  bool operator==(Rboolean rhs) const noexcept { return operator==(r_bool(rhs)); }
  bool operator==(int rhs) const noexcept { return operator==(r_bool(rhs)); }

 private:
  static constexpr int na = std::numeric_limits<int>::min();
  static constexpr int from_int(int value) noexcept {
    return (value == static_cast<int>(FALSE)) ? FALSE
           : (value == static_cast<int>(na))  ? na
                                              : TRUE;
  }
  int value_ = na;
};

inline std::ostream& operator<<(std::ostream& os, r_bool const& value) {
  os << ((value == TRUE) ? "TRUE" : "FALSE");
  return os;
}

template <typename T, typename R = void>
using enable_if_r_bool = enable_if_t<std::is_same<T, r_bool>::value, R>;

template <typename T>
enable_if_r_bool<T, SEXP> as_sexp(T from) {
  sexp res = Rf_allocVector(LGLSXP, 1);
  unwind_protect([&] { SET_LOGICAL_ELT(res.data(), 0, from); });
  return res;
}

template <>
inline r_bool na() {
  return NA_LOGICAL;
}

namespace traits {
template <>
struct get_underlying_type<r_bool> {
  using type = int;
};
}  // namespace traits

}  // namespace cpp4r
