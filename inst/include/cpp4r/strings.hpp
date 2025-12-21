#pragma once

#include <initializer_list>
#include <string>

#include "cpp4r/R.hpp"
#include "cpp4r/as.hpp"
#include "cpp4r/attribute_proxy.hpp"
#include "cpp4r/named_arg.hpp"
#include "cpp4r/protect.hpp"
#include "cpp4r/r_string.hpp"
#include "cpp4r/r_vector.hpp"
#include "cpp4r/sexp.hpp"

namespace cpp4r {

template <>
inline SEXPTYPE r_vector<r_string>::get_sexptype() {
  return STRSXP;
}

template <>
inline typename r_vector<r_string>::underlying_type r_vector<r_string>::get_elt(
    SEXP x, R_xlen_t i) {
  return STRING_ELT(x, i);
}

template <>
inline typename r_vector<r_string>::underlying_type* r_vector<r_string>::get_p(bool,
                                                                               SEXP) {
  return nullptr;
}

template <>
inline typename r_vector<r_string>::underlying_type const*
r_vector<r_string>::get_const_p(bool is_altrep, SEXP data) {
  return is_altrep ? nullptr : STRING_PTR_RO(data);
}

template <>
inline void r_vector<r_string>::get_region(SEXP x, R_xlen_t i, R_xlen_t n,
                                           typename r_vector::underlying_type* buf) {
  cpp4r::stop("Unreachable!");
}

template <>
inline bool r_vector<r_string>::const_iterator::use_buf(bool is_altrep) {
  return false;
}

typedef r_vector<r_string> strings;

namespace writable {

template <>
inline void r_vector<r_string>::set_elt(
    SEXP x, R_xlen_t i, typename r_vector<r_string>::underlying_type value) {
  SET_STRING_ELT(x, i, value);
}

template <>
template <typename U, typename std::enable_if<std::is_same<U, r_string>::value>::type*>
inline void r_vector<r_string>::push_back(const std::string& value) {
  while (this->length_ >= this->capacity_) {
    this->reserve(this->capacity_ == 0 ? 1 : this->capacity_ * 2);
  }
  set_elt(this->data_, this->length_,
          Rf_mkCharLenCE(value.c_str(), value.size(), CE_UTF8));
  ++this->length_;
}

inline bool operator==(const r_vector<r_string>::proxy& lhs, r_string rhs) {
  return static_cast<r_string>(lhs).operator==(static_cast<std::string>(rhs).c_str());
}

inline SEXP alloc_or_copy(const SEXP data) {
  switch (detail::r_typeof(data)) {
    case CHARSXP:
      return cpp4r::r_vector<r_string>(safe[Rf_allocVector](STRSXP, 1));
    case STRSXP:
      return safe[Rf_shallow_duplicate](data);
    default:
      throw type_error(STRSXP, detail::r_typeof(data));
  }
}

inline SEXP alloc_if_charsxp(const SEXP data) {
  switch (detail::r_typeof(data)) {
    case CHARSXP:
      return cpp4r::r_vector<r_string>(safe[Rf_allocVector](STRSXP, 1));
    case STRSXP:
      return data;
    default:
      throw type_error(STRSXP, detail::r_typeof(data));
  }
}

template <>
inline r_vector<r_string>::r_vector(const SEXP& data)
    : cpp4r::r_vector<r_string>(alloc_or_copy(data)), capacity_(this->length_) {
  if (detail::r_typeof(data) == CHARSXP) SET_STRING_ELT(this->data_, 0, data);
}

template <>
inline r_vector<r_string>::r_vector(SEXP&& data)
    : cpp4r::r_vector<r_string>(alloc_if_charsxp(data)), capacity_(this->length_) {
  if (detail::r_typeof(data) == CHARSXP) SET_STRING_ELT(this->data_, 0, data);
}

template <>
inline r_vector<r_string>::r_vector(std::initializer_list<r_string> il)
    : cpp4r::r_vector<r_string>(safe[Rf_allocVector](STRSXP, il.size())),
      capacity_(il.size()) {
  unwind_protect([&] {
    auto it = il.begin();
    for (R_xlen_t i = 0; i < this->capacity_; ++i, ++it) {
      typename r_vector<r_string>::underlying_type elt =
          static_cast<typename r_vector<r_string>::underlying_type>(*it);
      if (elt == NA_STRING) {
        set_elt(this->data_, i, elt);
      } else {
        set_elt(this->data_, i, Rf_mkCharCE(Rf_translateCharUTF8(elt), CE_UTF8));
      }
    }
  });
}

typedef r_vector<r_string> strings;

template <typename T>
inline void r_vector<T>::push_back(const named_arg& value) {
  push_back(value.value());
  if (Rf_xlength(this->names()) == 0) {
    cpp4r::writable::strings new_nms(this->capacity_);
    new_nms[this->length_ - 1] = value.name();
    this->names() = new_nms;
  } else {
    cpp4r::writable::strings nms(this->names());
    nms[this->length_ - 1] = value.name();
    this->names() = nms;
  }
}

}  // namespace writable

}  // namespace cpp4r
