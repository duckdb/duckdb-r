#pragma once

#include <complex>
#include <initializer_list>

#include "cpp4r/R.hpp"
#include "cpp4r/as.hpp"
#include "cpp4r/protect.hpp"
#include "cpp4r/r_complex.hpp"
#include "cpp4r/r_vector.hpp"
#include "cpp4r/sexp.hpp"

#ifndef SET_COMPLEX_ELT
#define SET_COMPLEX_ELT(x, i, v) (COMPLEX(x)[i] = v)
#endif

namespace cpp4r {

template <>
inline SEXPTYPE r_vector<r_complex>::get_sexptype() {
  return CPLXSXP;
}

template <>
inline typename r_vector<r_complex>::underlying_type r_vector<r_complex>::get_elt(
    SEXP x, R_xlen_t i) {
  return COMPLEX_ELT(x, i);
}

template <>
inline typename r_vector<r_complex>::underlying_type* r_vector<r_complex>::get_p(
    bool is_altrep, SEXP data) {
  return COMPLEX(data);
}

template <>
inline typename r_vector<r_complex>::underlying_type const*
r_vector<r_complex>::get_const_p(bool is_altrep, SEXP data) {
  return COMPLEX(data);
}

template <>
inline void r_vector<r_complex>::get_region(SEXP x, R_xlen_t i, R_xlen_t n,
                                            typename r_vector::underlying_type* buf) {
  COMPLEX_GET_REGION(x, i, n, buf);
}

template <>
inline bool r_vector<r_complex>::generic_const_iterator::use_buf(bool is_altrep) {
  return is_altrep;
}

typedef r_vector<r_complex> complexes;

namespace writable {

template <>
inline void r_vector<r_complex>::set_elt(
    SEXP x, R_xlen_t i, typename cpp4r::r_vector<r_complex>::underlying_type value) {
  COMPLEX(x)[i] = value;
}

inline bool operator==(const r_vector<r_complex>::proxy& lhs, r_complex rhs) {
  return static_cast<r_complex>(lhs) == rhs;
}

inline bool operator!=(const r_vector<r_complex>::proxy& lhs, r_complex rhs) {
  return !(lhs == rhs);
}

typedef r_vector<r_complex> complexes;

}  // namespace writable

inline complexes as_complexes(SEXP x) {
  SEXPTYPE type = detail::r_typeof(x);
  if (type == CPLXSXP) return complexes(x);

  if (type == INTSXP) {
    R_xlen_t len = Rf_xlength(x);
    writable::complexes ret(len);
    const int* CPP4R_RESTRICT src = INTEGER(x);
    Rcomplex* CPP4R_RESTRICT dst = COMPLEX(ret.data());

    for (R_xlen_t i = 0; i < len; ++i) {
      if (src[i] == NA_INTEGER) {
        dst[i].r = NA_REAL;
        dst[i].i = NA_REAL;
      } else {
        dst[i].r = static_cast<double>(src[i]);
        dst[i].i = 0.0;
      }
    }
    return ret;
  }

  throw type_error(CPLXSXP, type);
}

class complex_vector {
 public:
  explicit complex_vector(SEXP x) : data_(COMPLEX(x)), size_(Rf_length(x)) {}
  std::complex<double> operator[](R_xlen_t i) const { return {data_[i].r, data_[i].i}; }
  size_t size() const { return size_; }

 private:
  Rcomplex* data_;
  size_t size_;
};

template <typename T>
inline std::complex<T>& operator+=(std::complex<T>& lhs, const cpp4r::r_complex& rhs) {
  lhs.real(lhs.real() + rhs.real());
  lhs.imag(lhs.imag() + rhs.imag());
  return lhs;
}

namespace writable {

template <>
inline r_vector<r_complex>::r_vector(std::initializer_list<r_complex> il)
    : cpp4r::r_vector<r_complex>(safe[Rf_allocVector](CPLXSXP, il.size())),
      capacity_(il.size()) {
  auto it = il.begin();
  if (data_p_ != nullptr) {
    for (R_xlen_t i = 0; i < capacity_; ++i, ++it) {
      data_p_[i] = static_cast<underlying_type>(*it);
    }
  } else {
    for (R_xlen_t i = 0; i < capacity_; ++i, ++it) {
      set_elt(data_, i, static_cast<underlying_type>(*it));
    }
  }
}

}  // namespace writable

template <>
inline bool operator==(const r_vector<r_complex>& lhs,
                       const r_vector<r_complex>& rhs) noexcept {
  if (lhs.size() != rhs.size()) return false;
  for (R_xlen_t i = 0; i < lhs.size(); ++i) {
    if (!(lhs[i] == rhs[i])) return false;
  }
  return true;
}

template <>
inline bool operator!=(const r_vector<r_complex>& lhs,
                       const r_vector<r_complex>& rhs) noexcept {
  return !(lhs == rhs);
}

}  // namespace cpp4r
