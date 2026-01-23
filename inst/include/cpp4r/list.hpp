#pragma once

#include <initializer_list>

#include "cpp4r/R.hpp"
#include "cpp4r/attribute_proxy.hpp"
#include "cpp4r/protect.hpp"
#include "cpp4r/r_string.hpp"
#include "cpp4r/r_vector.hpp"
#include "cpp4r/sexp.hpp"

namespace cpp4r {

template <>
inline SEXPTYPE r_vector<SEXP>::get_sexptype() {
  return VECSXP;
}

template <>
inline typename r_vector<SEXP>::underlying_type r_vector<SEXP>::get_elt(SEXP x,
                                                                        R_xlen_t i) {
  return VECTOR_ELT(x, i);
}

template <>
inline typename r_vector<SEXP>::underlying_type* r_vector<SEXP>::get_p(bool, SEXP) {
  return nullptr;
}

template <>
inline typename r_vector<SEXP>::underlying_type const* r_vector<SEXP>::get_const_p(
    bool is_altrep, SEXP data) {
  if (is_altrep) return nullptr;
#if defined(R_VERSION) && R_VERSION >= R_Version(4, 5, 0)
  return VECTOR_PTR_RO(data);
#else
  return nullptr;
#endif
}

template <>
inline SEXP r_vector<SEXP>::get_oob() {
  return R_NilValue;
}

template <>
inline void r_vector<SEXP>::get_region(SEXP x, R_xlen_t i, R_xlen_t n,
                                       typename r_vector::underlying_type* buf) {
  cpp4r::stop("Unreachable!");
}

template <>
inline bool r_vector<SEXP>::const_iterator::use_buf(bool is_altrep) {
  return false;
}

typedef r_vector<SEXP> list;

namespace writable {

template <>
inline void r_vector<SEXP>::set_elt(SEXP x, R_xlen_t i,
                                    typename r_vector::underlying_type value) {
  SET_VECTOR_ELT(x, i, value);
}

template <>
inline r_vector<SEXP>::r_vector(std::initializer_list<named_arg> il)
    : cpp4r::r_vector<SEXP>(safe[Rf_allocVector](VECSXP, il.size())),
      capacity_(il.size()) {
  unwind_protect([&] {
    SEXP names = PROTECT(Rf_allocVector(STRSXP, capacity_));
    Rf_setAttrib(data_, R_NamesSymbol, names);

    auto it = il.begin();
    for (R_xlen_t i = 0; i < capacity_; ++i, ++it) {
      set_elt(data_, i, it->value());
      SET_STRING_ELT(names, i, Rf_mkCharCE(it->name(), CE_UTF8));
    }
    UNPROTECT(1);
  });
}

template <>
template <typename U>
inline r_vector<SEXP>::proxy& r_vector<SEXP>::proxy::operator=(const U& rhs) {
  set(as_sexp(rhs));
  return *this;
}

typedef r_vector<SEXP> list;

}  // namespace writable

}  // namespace cpp4r
