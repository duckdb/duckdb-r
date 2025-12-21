#pragma once

#include "cpp4r/cpp_version.hpp"  // for CPP4R optimization macros
#include "cpp4r/r_vector_fwd.hpp"

namespace cpp4r {

// Read-only r_vector implementations

template <typename T>
inline r_vector<T>::~r_vector() {
  detail::store::release(protect_);
}

// Constructor initialization order matches member declaration order:
// data_, data_p_, length_, protect_, is_altrep_
template <typename T>
inline r_vector<T>::r_vector(const SEXP data)
    : data_(valid_type(data)),
      data_p_(get_p(ALTREP(data), data)),
      length_(Rf_xlength(data)),
      protect_(detail::store::insert(data)),
      is_altrep_(ALTREP(data)) {}

template <typename T>
inline r_vector<T>::r_vector(const SEXP data, bool is_altrep)
    : data_(valid_type(data)),
      data_p_(get_p(is_altrep, data)),
      length_(Rf_xlength(data)),
      protect_(detail::store::insert(data)),
      is_altrep_(is_altrep) {}

// We are in read-only space so we can just copy over all properties except for
// `protect_`, which we need to manage on our own. `x` persists after this call, so we
// don't clear anything.
template <typename T>
inline r_vector<T>::r_vector(const r_vector& x) {
  data_ = x.data_;
  protect_ = detail::store::insert(data_);
  is_altrep_ = x.is_altrep_;
  data_p_ = x.data_p_;
  length_ = x.length_;
}

// `x` here is a temporary value, it is going to be destructed right after this.
// Take ownership over all `x` details, including `protect_`.
// Importantly, set `x.protect_` to `R_NilValue` to prevent the `x` destructor from
// releasing the object that we now own.
template <typename T>
inline r_vector<T>::r_vector(r_vector&& x) {
  data_ = x.data_;
  protect_ = x.protect_;
  is_altrep_ = x.is_altrep_;
  data_p_ = x.data_p_;
  length_ = x.length_;

  // Important for `x.protect_`, extra check for everything else
  x.data_ = R_NilValue;
  x.protect_ = R_NilValue;
  x.is_altrep_ = false;
  x.data_p_ = nullptr;
  x.length_ = 0;
}

// `x` here is writable, meaning the underlying `SEXP` could have more `capacity` than
// a read only equivalent would expect. This means we have to go through `SEXP` first,
// to truncate the writable data, and then we can wrap it in a read only `r_vector`.
//
// It would be the same scenario if we came from a writable temporary, i.e.
// `writable::r_vector<T>&& x`, so we let this method handle both scenarios.
template <typename T>
inline r_vector<T>::r_vector(const writable::r_vector<T>& x)
    : r_vector(static_cast<SEXP>(x)) {}

// Same reasoning as `r_vector(const r_vector& x)` constructor
template <typename T>
inline r_vector<T>& r_vector<T>::operator=(const r_vector& rhs) {
  if (data_ == rhs.data_) {
    return *this;
  }

  // Release existing object that we protect
  detail::store::release(protect_);

  data_ = rhs.data_;
  protect_ = detail::store::insert(data_);
  is_altrep_ = rhs.is_altrep_;
  data_p_ = rhs.data_p_;
  length_ = rhs.length_;

  return *this;
}

// Same reasoning as `r_vector(r_vector&& x)` constructor
template <typename T>
inline r_vector<T>& r_vector<T>::operator=(r_vector&& rhs) {
  if (data_ == rhs.data_) {
    return *this;
  }

  // Release existing object that we protect
  detail::store::release(protect_);

  data_ = rhs.data_;
  protect_ = rhs.protect_;
  is_altrep_ = rhs.is_altrep_;
  data_p_ = rhs.data_p_;
  length_ = rhs.length_;

  // Important for `rhs.protect_`, extra check for everything else
  rhs.data_ = R_NilValue;
  rhs.protect_ = R_NilValue;
  rhs.is_altrep_ = false;
  rhs.data_p_ = nullptr;
  rhs.length_ = 0;

  return *this;
}

template <typename T>
inline r_vector<T>::operator SEXP() const {
  return data_;
}

template <typename T>
inline r_vector<T>::operator sexp() const {
  return data_;
}

#ifdef LONG_VECTOR_SUPPORT
template <typename T>
CPP4R_ALWAYS_INLINE T r_vector<T>::operator[](const int pos) const {
  return operator[](static_cast<R_xlen_t>(pos));
}
#endif

template <typename T>
CPP4R_ALWAYS_INLINE T r_vector<T>::operator[](const R_xlen_t pos) const {
  // Handles ALTREP, VECSXP, and STRSXP cases through `get_elt()`
#if CPP4R_HAS_CXX20
  if (data_p_ != nullptr) [[likely]] {
    return static_cast<T>(data_p_[pos]);
  } else {
    return static_cast<T>(get_elt(data_, pos));
  }
#else
  const underlying_type elt =
      CPP4R_LIKELY(data_p_ != nullptr) ? data_p_[pos] : get_elt(data_, pos);
  return static_cast<T>(elt);
#endif
}

template <typename T>
CPP4R_ALWAYS_INLINE T r_vector<T>::operator[](const size_type pos) const {
  return operator[](static_cast<R_xlen_t>(pos));
}

template <typename T>
inline T r_vector<T>::operator[](const r_string& name) const {
  SEXP names = this->names();
  R_xlen_t size = Rf_xlength(names);

  for (R_xlen_t pos = 0; pos < size; ++pos) {
    auto cur = Rf_translateCharUTF8(STRING_ELT(names, pos));
    if (name == cur) {
      return operator[](pos);
    }
  }

  return get_oob();
}

#ifdef LONG_VECTOR_SUPPORT
template <typename T>
inline T r_vector<T>::at(const int pos) const {
  return at(static_cast<R_xlen_t>(pos));
}
#endif

template <typename T>
inline T r_vector<T>::at(const R_xlen_t pos) const {
  if (pos < 0 || pos >= length_) {
    throw std::out_of_range("r_vector");
  }

  return operator[](pos);
}

template <typename T>
inline T r_vector<T>::at(const size_type pos) const {
  return at(static_cast<R_xlen_t>(pos));
}

template <typename T>
inline T r_vector<T>::at(const r_string& name) const {
  return operator[](name);
}

template <typename T>
inline bool r_vector<T>::contains(const r_string& name) const {
  SEXP names = this->names();
  R_xlen_t size = Rf_xlength(names);

  for (R_xlen_t pos = 0; pos < size; ++pos) {
    auto cur = Rf_translateCharUTF8(STRING_ELT(names, pos));
    if (name == cur) {
      return true;
    }
  }

  return false;
}

template <typename T>
inline bool r_vector<T>::is_altrep() const {
  return is_altrep_;
}

template <typename T>
inline bool r_vector<T>::named() const {
  return Rf_getAttrib(data_, R_NamesSymbol) != R_NilValue;
}

template <typename T>
CPP4R_ALWAYS_INLINE R_xlen_t r_vector<T>::size() const {
  return length_;
}

template <typename T>
CPP4R_ALWAYS_INLINE bool r_vector<T>::empty() const {
  return (!(this->size() > 0));
}

// Provide access to the underlying data, mainly for interface
// compatibility with std::vector
template <typename T>
CPP4R_ALWAYS_INLINE SEXP r_vector<T>::data() const {
  return data_;
}

template <typename T>
inline const sexp r_vector<T>::attr(const char* name) const {
  return SEXP(attribute_proxy<r_vector<T>>(*this, name));
}

template <typename T>
inline const sexp r_vector<T>::attr(const std::string& name) const {
  return SEXP(attribute_proxy<r_vector<T>>(*this, name.c_str()));
}

template <typename T>
inline const sexp r_vector<T>::attr(SEXP name) const {
  return SEXP(attribute_proxy<r_vector<T>>(*this, name));
}

template <typename T>
inline r_vector<r_string> r_vector<T>::names() const {
  SEXP nms = Rf_getAttrib(data_, R_NamesSymbol);
  if (nms == R_NilValue) {
    return r_vector<r_string>();
  } else {
    return r_vector<r_string>(nms);
  }
}

template <typename T>
CPP4R_COLD inline T r_vector<T>::get_oob() {
  throw std::out_of_range("r_vector");
}

template <typename T>
inline SEXP r_vector<T>::valid_type(SEXP x) {
  const SEXPTYPE type = get_sexptype();

#if CPP4R_HAS_CXX20
  // C++20: Use standard [[unlikely]] attribute for error paths
  if (x == nullptr) [[unlikely]] {
    throw type_error(type, NILSXP);
  }
  if (detail::r_typeof(x) != type) [[unlikely]] {
    throw type_error(type, detail::r_typeof(x));
  }
#else
  // C++11-17: Use __builtin_expect
  if (CPP4R_UNLIKELY(x == nullptr)) {
    throw type_error(type, NILSXP);
  }
  if (CPP4R_UNLIKELY(detail::r_typeof(x) != type)) {
    throw type_error(type, detail::r_typeof(x));
  }
#endif

  return x;
}

template <typename T>
inline SEXP r_vector<T>::valid_length(SEXP x, R_xlen_t n) {
  R_xlen_t x_n = Rf_xlength(x);

  if (x_n == n) {
    return x;
  }

  char message[128];
  snprintf(message, 128,
           "Invalid input length, expected '%" CPP4R_PRIdXLEN_T
           "' actual '%" CPP4R_PRIdXLEN_T "'.",
           n, x_n);

  throw std::length_error(message);
}

template <typename T>
CPP4R_ALWAYS_INLINE typename r_vector<T>::const_iterator r_vector<T>::begin() const {
#if CPP4R_HAS_CXX17
  if constexpr (traits::use_raw_pointer<T>::value) {
    return reinterpret_cast<const_iterator>(data_p_);
  } else {
    return generic_const_iterator(this, 0);
  }
#else
  return begin_impl(traits::use_raw_pointer<T>{});
#endif
}

#if !CPP4R_HAS_CXX17
template <typename T>
CPP4R_ALWAYS_INLINE
    typename r_vector<T>::const_iterator r_vector<T>::begin_impl(std::true_type) const {
  return reinterpret_cast<const_iterator>(data_p_);
}

template <typename T>
CPP4R_ALWAYS_INLINE typename r_vector<T>::const_iterator r_vector<T>::begin_impl(
    std::false_type) const {
  return generic_const_iterator(this, 0);
}
#endif

template <typename T>
CPP4R_ALWAYS_INLINE typename r_vector<T>::const_iterator r_vector<T>::end() const {
#if CPP4R_HAS_CXX17
  if constexpr (traits::use_raw_pointer<T>::value) {
    return reinterpret_cast<const_iterator>(data_p_ + length_);
  } else {
    return generic_const_iterator(this, length_);
  }
#else
  return end_impl(traits::use_raw_pointer<T>{});
#endif
}

#if !CPP4R_HAS_CXX17
template <typename T>
CPP4R_ALWAYS_INLINE
    typename r_vector<T>::const_iterator r_vector<T>::end_impl(std::true_type) const {
  return reinterpret_cast<const_iterator>(data_p_ + length_);
}

template <typename T>
CPP4R_ALWAYS_INLINE typename r_vector<T>::const_iterator r_vector<T>::end_impl(
    std::false_type) const {
  return generic_const_iterator(this, length_);
}
#endif

template <typename T>
CPP4R_ALWAYS_INLINE typename r_vector<T>::const_iterator r_vector<T>::cbegin() const {
  return begin();
}

template <typename T>
CPP4R_ALWAYS_INLINE typename r_vector<T>::const_iterator r_vector<T>::cend() const {
  return end();
}

template <typename T>
r_vector<T>::generic_const_iterator::generic_const_iterator(const r_vector* data,
                                                            R_xlen_t pos)
    : data_(data), pos_(pos), buf_() {
  // Only use the ALTREP region buffer when the specialization allows it and the
  // vector is larger than the tunable threshold. Small vectors are faster when
  // accessed per-element.
  if (use_buf(data_->is_altrep()) &&
      data_->size() >
          static_cast<R_xlen_t>(r_vector<T>::generic_const_iterator::BUF_THRESHOLD)) {
    fill_buf(pos);
  }
}

template <typename T>
CPP4R_ALWAYS_INLINE typename r_vector<T>::generic_const_iterator&
r_vector<T>::generic_const_iterator::operator++() {
  ++pos_;
#if CPP4R_HAS_CXX20
  // C++20: Use standard [[unlikely]] attribute (better understood by modern optimizers)
  if (use_buf(data_->is_altrep()) && pos_ >= block_start_ + length_) [[unlikely]] {
    fill_buf(pos_);
  }
#else
  // C++11-17: Use __builtin_expect
  if (CPP4R_UNLIKELY(use_buf(data_->is_altrep()) && pos_ >= block_start_ + length_)) {
    fill_buf(pos_);
  }
#endif
  return *this;
}

template <typename T>
inline typename r_vector<T>::generic_const_iterator&
r_vector<T>::generic_const_iterator::operator--() {
  --pos_;
  if (use_buf(data_->is_altrep()) &&
      data_->size() >
          static_cast<R_xlen_t>(r_vector<T>::generic_const_iterator::BUF_THRESHOLD) &&
      pos_ > 0 && pos_ < block_start_) {
    fill_buf(std::max(0_xl, pos_ - static_cast<R_xlen_t>(
                                       r_vector<T>::generic_const_iterator::BUF_CAP)));
  }
  return *this;
}

template <typename T>
inline typename r_vector<T>::generic_const_iterator&
r_vector<T>::generic_const_iterator::operator+=(R_xlen_t i) {
  pos_ += i;
  if (use_buf(data_->is_altrep()) && pos_ >= block_start_ + length_) {
    fill_buf(pos_);
  }
  return *this;
}

template <typename T>
inline typename r_vector<T>::generic_const_iterator&
r_vector<T>::generic_const_iterator::operator-=(R_xlen_t i) {
  pos_ -= i;
  if (use_buf(data_->is_altrep()) && pos_ >= block_start_ + length_) {
    fill_buf(std::max(0_xl, pos_ - static_cast<R_xlen_t>(
                                       r_vector<T>::generic_const_iterator::BUF_CAP)));
  }
  return *this;
}

template <typename T>
inline bool r_vector<T>::generic_const_iterator::operator!=(
    const r_vector::generic_const_iterator& other) const {
  return pos_ != other.pos_;
}

template <typename T>
inline bool r_vector<T>::generic_const_iterator::operator==(
    const r_vector::generic_const_iterator& other) const {
  return pos_ == other.pos_;
}

template <typename T>
inline ptrdiff_t r_vector<T>::generic_const_iterator::operator-(
    const r_vector::generic_const_iterator& other) const {
  return pos_ - other.pos_;
}

template <typename T>
inline typename r_vector<T>::generic_const_iterator
r_vector<T>::generic_const_iterator::operator+(R_xlen_t rhs) {
  auto it = *this;
  it += rhs;
  return it;
}

template <typename T>
inline typename r_vector<T>::const_iterator r_vector<T>::find(
    const r_string& name) const {
  SEXP names = this->names();
  R_xlen_t size = Rf_xlength(names);

  for (R_xlen_t pos = 0; pos < size; ++pos) {
    auto cur = Rf_translateCharUTF8(STRING_ELT(names, pos));
    if (name == cur) {
      return begin() + pos;
    }
  }

  return end();
}

template <typename T>
inline typename r_vector<T>::const_iterator r_vector<T>::find(
    const std::vector<std::string>& names_cache, const r_string& name) const {
  for (R_xlen_t pos = 0; pos < static_cast<R_xlen_t>(names_cache.size()); ++pos) {
    if (names_cache[pos] == static_cast<std::string>(name)) {
      return begin() + pos;
    }
  }
  return end();
}

template <typename T>
inline typename r_vector<T>::const_iterator r_vector<T>::find_cached(
    const std::vector<std::string>& names_cache, const r_string& name) const {
  for (R_xlen_t pos = 0; pos < static_cast<R_xlen_t>(names_cache.size()); ++pos) {
    if (names_cache[pos] == static_cast<std::string>(name)) {
      return begin() + pos;
    }
  }
  return end();
}

template <typename T>
CPP4R_ALWAYS_INLINE T r_vector<T>::generic_const_iterator::operator*() const {
#if CPP4R_HAS_CXX20
  // C++20: Use standard [[unlikely]] attribute
  if (use_buf(data_->is_altrep()) &&
      data_->size() >
          static_cast<R_xlen_t>(r_vector<T>::generic_const_iterator::BUF_THRESHOLD))
      [[unlikely]] {
    // Use pre-loaded buffer for compatible ALTREP types
    return static_cast<T>(buf_[pos_ - block_start_]);
  } else {
    // Otherwise pass through to normal retrieval method (common case)
    return data_->operator[](pos_);
  }
#else
  // C++11-17: Use __builtin_expect
  if (CPP4R_UNLIKELY(use_buf(data_->is_altrep()) &&
                     data_->size() >
                         static_cast<R_xlen_t>(
                             r_vector<T>::generic_const_iterator::BUF_THRESHOLD))) {
    // Use pre-loaded buffer for compatible ALTREP types
    return static_cast<T>(buf_[pos_ - block_start_]);
  } else {
    // Otherwise pass through to normal retrieval method (common case)
    return data_->operator[](pos_);
  }
#endif
}

template <typename T>
inline void r_vector<T>::generic_const_iterator::fill_buf(R_xlen_t pos) {
  using namespace cpp4r::literals;
  // Guard against buffering for small vectors — callers should avoid invoking
  // this when data is small, but double-guard here to be safe. If the vector
  // is small, avoid filling the buffer and leave length_ == 0.
  if (data_->size() <=
      static_cast<R_xlen_t>(r_vector<T>::generic_const_iterator::BUF_THRESHOLD)) {
    length_ = 0;
    block_start_ = pos;
    return;
  }

  // Limit region size to the iterator buffer capacity (BUF_CAP) to avoid
  // overrunning the buffer and to keep fills predictable.
  length_ = static_cast<R_xlen_t>(
      std::min(static_cast<R_xlen_t>(r_vector<T>::generic_const_iterator::BUF_CAP),
               data_->size() - pos));
  get_region(data_->data_, pos, length_, buf_.data());
  block_start_ = pos;
}

}  // namespace cpp4r
