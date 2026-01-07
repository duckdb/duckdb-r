#pragma once

#include <initializer_list>

#include "R_ext/Arith.h"
#include "cpp4r/R.hpp"
#include "cpp4r/as.hpp"
#include "cpp4r/cpp_version.hpp"
#include "cpp4r/protect.hpp"
#include "cpp4r/r_bool.hpp"
#include "cpp4r/r_vector.hpp"
#include "cpp4r/sexp.hpp"

namespace cpp4r {

template <>
inline SEXPTYPE r_vector<double>::get_sexptype() {
  return REALSXP;
}

template <>
inline typename r_vector<double>::underlying_type r_vector<double>::get_elt(SEXP x,
                                                                            R_xlen_t i) {
  return REAL_ELT(x, i);
}

template <>
inline typename r_vector<double>::underlying_type* r_vector<double>::get_p(bool is_altrep,
                                                                           SEXP data) {
  return REAL(data);
}

template <>
inline typename r_vector<double>::underlying_type const* r_vector<double>::get_const_p(
    bool is_altrep, SEXP data) {
  return REAL(data);
}

template <>
inline void r_vector<double>::get_region(SEXP x, R_xlen_t i, R_xlen_t n,
                                         typename r_vector::underlying_type* buf) {
  REAL_GET_REGION(x, i, n, buf);
}

template <>
inline bool r_vector<double>::generic_const_iterator::use_buf(bool is_altrep) {
  return is_altrep;
}

typedef r_vector<double> doubles;

namespace writable {

template <>
inline void r_vector<double>::set_elt(SEXP x, R_xlen_t i,
                                      typename r_vector::underlying_type value) {
  SET_REAL_ELT(x, i, value);
}

typedef r_vector<double> doubles;

}  // namespace writable

template <>
inline const double* CPP4R_RESTRICT r_vector<double>::data_ptr() const noexcept {
  return data_p_;
}

namespace writable {
template <>
inline double* CPP4R_RESTRICT r_vector<double>::data_ptr_writable() noexcept {
  return data_p_;
}

template <>
inline const double* CPP4R_RESTRICT r_vector<double>::data_ptr() const noexcept {
  return data_p_;
}
}  // namespace writable

typedef r_vector<int> integers;
typedef r_vector<r_bool> logicals;

inline doubles as_doubles(SEXP x) {
  SEXPTYPE type = detail::r_typeof(x);
  if (type == REALSXP) return doubles(x);

  if (type == INTSXP || type == LGLSXP) {
    R_xlen_t len = Rf_xlength(x);
    writable::doubles ret(len);
    const int* CPP4R_RESTRICT src = (type == INTSXP) ? INTEGER(x) : LOGICAL(x);
    double* CPP4R_RESTRICT dst = REAL(ret.data());
    int na_val = (type == INTSXP) ? NA_INTEGER : NA_LOGICAL;

    for (R_xlen_t i = 0; i < len; ++i) {
      dst[i] = (src[i] == na_val) ? NA_REAL : static_cast<double>(src[i]);
    }
    return ret;
  }

  throw type_error(REALSXP, type);
}

template <>
inline double na() {
  return NA_REAL;
}

}  // namespace cpp4r
