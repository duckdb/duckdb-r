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
inline SEXPTYPE r_vector<int>::get_sexptype() {
  return INTSXP;
}

template <>
inline typename r_vector<int>::underlying_type r_vector<int>::get_elt(SEXP x,
                                                                      R_xlen_t i) {
  return INTEGER_ELT(x, i);
}

template <>
inline typename r_vector<int>::underlying_type* r_vector<int>::get_p(bool is_altrep,
                                                                     SEXP data) {
  return INTEGER(data);
}

template <>
inline typename r_vector<int>::underlying_type const* r_vector<int>::get_const_p(
    bool is_altrep, SEXP data) {
  return INTEGER(data);
}

template <>
inline void r_vector<int>::get_region(SEXP x, R_xlen_t i, R_xlen_t n,
                                      typename r_vector::underlying_type* buf) {
  INTEGER_GET_REGION(x, i, n, buf);
}

template <>
inline bool r_vector<int>::generic_const_iterator::use_buf(bool is_altrep) {
  return is_altrep;
}

typedef r_vector<int> integers;

namespace writable {

template <>
inline void r_vector<int>::set_elt(SEXP x, R_xlen_t i,
                                   typename r_vector::underlying_type value) {
  SET_INTEGER_ELT(x, i, value);
}

typedef r_vector<int> integers;

}  // namespace writable

template <>
inline int na() {
  return NA_INTEGER;
}

typedef r_vector<double> doubles;
typedef r_vector<r_bool> logicals;

inline integers as_integers(SEXP x) {
  SEXPTYPE type = detail::r_typeof(x);
  if (type == INTSXP) return integers(x);

  if (type == REALSXP) {
    R_xlen_t len = Rf_xlength(x);
    const double* CPP4R_RESTRICT src = REAL(x);

    // Validate all values are integer-like
    for (R_xlen_t i = 0; i < len; ++i) {
      if (!ISNA(src[i]) && !is_convertible_without_loss_to_integer(src[i])) {
        throw std::runtime_error("All elements must be integer-like");
      }
    }

    writable::integers ret(len);
    int* CPP4R_RESTRICT dst = INTEGER(ret.data());
    for (R_xlen_t i = 0; i < len; ++i) {
      dst[i] = ISNA(src[i]) ? NA_INTEGER : static_cast<int>(src[i]);
    }
    return ret;
  }

  if (type == LGLSXP) {
    R_xlen_t len = Rf_xlength(x);
    writable::integers ret(len);
    const int* CPP4R_RESTRICT src = LOGICAL(x);
    int* CPP4R_RESTRICT dst = INTEGER(ret.data());

    for (R_xlen_t i = 0; i < len; ++i) {
      dst[i] = (src[i] == NA_LOGICAL) ? NA_INTEGER : src[i];
    }
    return ret;
  }

  throw type_error(INTSXP, type);
}

}  // namespace cpp4r
