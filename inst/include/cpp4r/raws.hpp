#pragma once

#include <cstdint>
#include <initializer_list>

#include "Rversion.h"
#include "cpp4r/R.hpp"
#include "cpp4r/protect.hpp"
#include "cpp4r/r_vector.hpp"
#include "cpp4r/sexp.hpp"

namespace cpp4r {

namespace traits {
template <>
struct get_underlying_type<uint8_t> {
  using type = Rbyte;
};
}  // namespace traits

template <>
inline SEXPTYPE r_vector<uint8_t>::get_sexptype() {
  return RAWSXP;
}

template <>
inline typename r_vector<uint8_t>::underlying_type r_vector<uint8_t>::get_elt(
    SEXP x, R_xlen_t i) {
  return RAW_ELT(x, i);
}

template <>
inline typename r_vector<uint8_t>::underlying_type const* r_vector<uint8_t>::get_const_p(
    bool is_altrep, SEXP data) {
  return RAW_OR_NULL(data);
}

template <>
inline typename r_vector<uint8_t>::underlying_type* r_vector<uint8_t>::get_p(
    bool is_altrep, SEXP data) {
  return is_altrep ? nullptr : RAW(data);
}

template <>
inline void r_vector<uint8_t>::get_region(SEXP x, R_xlen_t i, R_xlen_t n,
                                          typename r_vector::underlying_type* buf) {
  RAW_GET_REGION(x, i, n, buf);
}

template <>
inline bool r_vector<uint8_t>::const_iterator::use_buf(bool is_altrep) {
  return is_altrep;
}

typedef r_vector<uint8_t> raws;

namespace writable {

template <>
inline void r_vector<uint8_t>::set_elt(SEXP x, R_xlen_t i,
                                       typename r_vector::underlying_type value) {
#if R_VERSION >= R_Version(4, 2, 0)
  SET_RAW_ELT(x, i, value);
#else
  RAW(x)[i] = value;
#endif
}

typedef r_vector<uint8_t> raws;

}  // namespace writable

}  // namespace cpp4r
