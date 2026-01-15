#pragma once

#include "cpp4r/r_vector_fwd.hpp"

namespace cpp4r {
namespace writable {

template <typename T>
inline r_vector<T>::r_vector(const SEXP& data)
    : cpp4r::r_vector<T>(safe[Rf_shallow_duplicate](data)), capacity_(length_) {}

template <typename T>
inline r_vector<T>::r_vector(SEXP&& data)
    : cpp4r::r_vector<T>(data), capacity_(length_) {}

template <typename T>
inline r_vector<T>::r_vector(const SEXP& data, bool is_altrep)
    : cpp4r::r_vector<T>(safe[Rf_shallow_duplicate](data), is_altrep),
      capacity_(length_) {}

template <typename T>
inline r_vector<T>::r_vector(SEXP&& data, bool is_altrep)
    : cpp4r::r_vector<T>(data, is_altrep), capacity_(length_) {}

// Fast-path constructor for freshly allocated data
// Optimized for performance-critical paths like matrix allocation
// Preconditions:
//   - data was just allocated by Rf_allocVector/Rf_allocMatrix
//   - data is NOT ALTREP (fresh allocations never are)
//   - data is owned (no duplicate needed)
template <typename T>
CPP4R_ALWAYS_INLINE r_vector<T>::r_vector(SEXP data, fresh_allocation_tag)
    : cpp4r::r_vector<T>(), capacity_(Rf_xlength(data)) {
  // Direct initialization bypassing parent constructor overhead
  data_ = data;
  protect_ = detail::store::insert(data);
  is_altrep_ = false;  // Fresh allocations are never ALTREP
  data_p_ = get_p(false, data);
  length_ = capacity_;
}

template <typename T>
inline r_vector<T>::r_vector(const r_vector& rhs) {
  // We don't want to just pass through to the read-only constructor because we'd
  // have to convert to `SEXP` first, which could truncate, and then we'd still have
  // to shallow duplicate after that to really ensure we have a duplicate, which can
  // result in too many copies (#369).
  //
  // Instead we take control of setting all fields to try and only duplicate 1 time.
  // If there is extra capacity in the `rhs`, that is also copied over. Resist the urge
  // to try and trim the extra capacity during the duplication. We really do want to do a
  // shallow duplicate to ensure that ALL attributes are copied over, including `dim` and
  // `dimnames`, which would be lost if we instead used `reserve_data()` to do a combined
  // duplicate + possible truncate. This is important for the `matrix` class.
  data_ = safe[Rf_shallow_duplicate](rhs.data_);
  protect_ = detail::store::insert(data_);
  is_altrep_ = ALTREP(data_);
  data_p_ = (data_ == R_NilValue) ? nullptr : get_p(is_altrep_, data_);
  length_ = rhs.length_;
  capacity_ = rhs.capacity_;
}

template <typename T>
inline r_vector<T>::r_vector(r_vector&& rhs) {
  // We don't want to pass through to the read-only constructor from a
  // `writable::r_vector<T>&& rhs` as that forces a truncation to be able to generate
  // a well-formed read-only vector. Instead, we take advantage of the fact that we
  // are going from writable input to writable output and just move everything over.
  //
  // This ends up looking very similar to the equivalent read-only constructor from a
  // read-only `r_vector&& rhs`, with the addition of moving the capacity.
  data_ = rhs.data_;
  protect_ = rhs.protect_;
  is_altrep_ = rhs.is_altrep_;
  data_p_ = rhs.data_p_;
  length_ = rhs.length_;
  capacity_ = rhs.capacity_;

  // Important for `rhs.protect_`, extra check for everything else
  rhs.data_ = R_NilValue;
  rhs.protect_ = R_NilValue;
  rhs.is_altrep_ = false;
  rhs.data_p_ = nullptr;
  rhs.length_ = 0;
  rhs.capacity_ = 0;
}

template <typename T>
inline r_vector<T>::r_vector(const cpp4r::r_vector<T>& rhs)
    : cpp4r::r_vector<T>(safe[Rf_shallow_duplicate](rhs.data_)), capacity_(rhs.length_) {}

template <typename T>
inline r_vector<T>::r_vector(std::initializer_list<T> il)
    : cpp4r::r_vector<T>(safe[Rf_allocVector](get_sexptype(), il.size())),
      capacity_(il.size()) {
  auto it = il.begin();

  if (data_p_ != nullptr) {
    for (R_xlen_t i = 0; i < capacity_; ++i, ++it) {
      data_p_[i] = static_cast<underlying_type>(*it);
    }
  } else {
    // Handles both the ALTREP and VECSXP cases
    for (R_xlen_t i = 0; i < capacity_; ++i, ++it) {
      set_elt(data_, i, static_cast<underlying_type>(*it));
    }
  }
}

template <typename T>
inline r_vector<T>::r_vector(std::initializer_list<named_arg> il)
    : cpp4r::r_vector<T>(safe[Rf_allocVector](get_sexptype(), il.size())),
      capacity_(il.size()) {
  auto it = il.begin();

  // SAFETY: Loop through once outside the `unwind_protect()` to perform the
  // validation that might `throw`.
  for (R_xlen_t i = 0; i < capacity_; ++i, ++it) {
    SEXP value = it->value();
    valid_type(value);
    valid_length(value, 1);
  }

  unwind_protect([&] {
    SEXP names;
    PROTECT(names = Rf_allocVector(STRSXP, capacity_));
    Rf_setAttrib(data_, R_NamesSymbol, names);

    auto it = il.begin();

    for (R_xlen_t i = 0; i < capacity_; ++i, ++it) {
      SEXP value = it->value();

      // SAFETY: We've validated type and length ahead of this.
      const underlying_type elt = get_elt(value, 0);

#if CPP4R_HAS_CXX17
      if constexpr (std::is_same<T, cpp4r::r_string>::value) {
        // Translate to UTF-8 before assigning for string types
        SEXP translated_elt = Rf_mkCharCE(Rf_translateCharUTF8(elt), CE_UTF8);

        if (data_p_ != nullptr) {
          data_p_[i] = translated_elt;
        } else {
          // Handles STRSXP case. VECSXP case has its own specialization.
          // We don't expect any ALTREP cases since we just freshly allocated `data_`.
          set_elt(data_, i, translated_elt);
        }
      } else {
        if (data_p_ != nullptr) {
          data_p_[i] = elt;
        } else {
          set_elt(data_, i, elt);
        }
      }
#else
      named_arg_assign_elt(i, elt, std::is_same<T, cpp4r::r_string>{});
#endif

      SEXP name = Rf_mkCharCE(it->name(), CE_UTF8);
      SET_STRING_ELT(names, i, name);
    }

    UNPROTECT(1);
  });
}

#if !CPP4R_HAS_CXX17
// Helper for named_arg constructor when T is r_string
template <typename T>
inline void r_vector<T>::named_arg_assign_elt(R_xlen_t i, underlying_type elt,
                                              std::true_type) {
  // Translate to UTF-8 before assigning for string types
  SEXP translated_elt = Rf_mkCharCE(Rf_translateCharUTF8(elt), CE_UTF8);

  if (data_p_ != nullptr) {
    data_p_[i] = translated_elt;
  } else {
    set_elt(data_, i, translated_elt);
  }
}

// Helper for named_arg constructor when T is not r_string
template <typename T>
inline void r_vector<T>::named_arg_assign_elt(R_xlen_t i, underlying_type elt,
                                              std::false_type) {
  if (data_p_ != nullptr) {
    data_p_[i] = elt;
  } else {
    set_elt(data_, i, elt);
  }
}
#endif

// Optimized size constructor using fast-path allocation
template <typename T>
CPP4R_ALWAYS_INLINE r_vector<T>::r_vector(const R_xlen_t size)
    : r_vector(safe[Rf_allocVector](get_sexptype(), size), fresh_allocation_tag{}) {}

template <typename T>
template <typename Iter>
inline r_vector<T>::r_vector(Iter first, Iter last) : r_vector() {
  reserve(last - first);
  while (first != last) {
    push_back(*first);
    ++first;
  }
}

template <typename T>
template <typename V, typename W>
inline r_vector<T>::r_vector(const V& obj) : r_vector() {
  auto first = obj.begin();
  auto last = obj.end();
  reserve(last - first);
  while (first != last) {
    push_back(*first);
    ++first;
  }
}

template <typename T>
inline r_vector<T>& r_vector<T>::operator=(const r_vector& rhs) {
  if (data_ == rhs.data_) {
    return *this;
  }

  // We don't release the old object until the end in case we throw an exception
  // during the duplicate.
  SEXP old_protect = protect_;

  // Unlike with move assignment operator, we can't just call the read only parent method.
  // We are in writable mode, so we must duplicate the `rhs` (since it isn't a temporary
  // we can just take ownership of) and recompute the properties from the duplicate.
  data_ = safe[Rf_shallow_duplicate](rhs.data_);
  protect_ = detail::store::insert(data_);
  is_altrep_ = ALTREP(data_);
  data_p_ = (data_ == R_NilValue) ? nullptr : get_p(is_altrep_, data_);
  length_ = rhs.length_;
  capacity_ = rhs.capacity_;

  detail::store::release(old_protect);

  return *this;
}

template <typename T>
inline r_vector<T>& r_vector<T>::operator=(r_vector&& rhs) {
  if (data_ == rhs.data_) {
    return *this;
  }

  // Call parent read only move assignment operator to move
  // all other properties, including protection handling
  cpp4r::r_vector<T>::operator=(std::move(rhs));

  // Handle fields specific to writable
  capacity_ = rhs.capacity_;

  rhs.capacity_ = 0;

  return *this;
}

template <typename T>
CPP4R_ALWAYS_INLINE r_vector<T>::operator SEXP() const {
  // Fast path: most common case - data is valid and length == capacity
  if (CPP4R_LIKELY(data_ != R_NilValue && length_ == capacity_)) {
    return data_;
  }

  // Slow paths for edge cases
  // Throwing away the const-ness is a bit gross, but we only modify
  // internal details here, and updating the internal data after we resize allows
  // statements like `Rf_setAttrib(<r_vector>, name, value)` to make sense, where
  // people expect that the SEXP inside the `<r_vector>` gets the updated attribute.
  auto* p = const_cast<r_vector<T>*>(this);

  if (CPP4R_UNLIKELY(data_ == R_NilValue)) {
    // Specially call out the `NULL` case, which can occur if immediately
    // returning a default constructed writable `r_vector` as a `SEXP`.
    p->resize(0);
    return data_;
  }

  // length_ < capacity_: Truncate the vector to its `length_`.
  // This unfortunately typically forces an allocation if the user has called
  // `push_back()` on a writable `r_vector`. Importantly, going through `resize()`
  // updates: `data_` and protection of it, `data_p_`, and `capacity_`.
  p->resize(length_);
  return data_;
}

#ifdef LONG_VECTOR_SUPPORT
template <typename T>
CPP4R_ALWAYS_INLINE
    typename r_vector<T>::reference r_vector<T>::operator[](const int pos) const {
  return operator[](static_cast<R_xlen_t>(pos));
}
#endif

template <typename T>
CPP4R_ALWAYS_INLINE
    typename r_vector<T>::reference r_vector<T>::operator[](const R_xlen_t pos) const {
#if CPP4R_HAS_CXX17
  if constexpr (traits::use_raw_pointer<T>::value) {
    return data_p_[pos];
  } else {
    if (CPP4R_UNLIKELY(is_altrep_)) {
      return {data_, pos, nullptr, true};
    }
    return {data_, pos, data_p_ != nullptr ? &data_p_[pos] : nullptr, false};
  }
#else
  return subscript_impl(pos, traits::use_raw_pointer<T>{});
#endif
}

#if !CPP4R_HAS_CXX17
template <typename T>
CPP4R_ALWAYS_INLINE
    typename r_vector<T>::reference r_vector<T>::subscript_impl(const R_xlen_t pos,
                                                                std::true_type) const {
  return data_p_[pos];
}

template <typename T>
CPP4R_ALWAYS_INLINE typename r_vector<T>::reference r_vector<T>::subscript_impl(
    const R_xlen_t pos, std::false_type) const {
  if (CPP4R_UNLIKELY(is_altrep_)) {
    return {data_, pos, nullptr, true};
  }
  return {data_, pos, data_p_ != nullptr ? &data_p_[pos] : nullptr, false};
}
#endif

template <typename T>
CPP4R_ALWAYS_INLINE
    typename r_vector<T>::reference r_vector<T>::operator[](const size_type pos) const {
  return operator[](static_cast<R_xlen_t>(pos));
}

template <typename T>
inline typename r_vector<T>::reference r_vector<T>::operator[](
    const r_string& name) const {
  SEXP names = PROTECT(this->names());
  R_xlen_t size = Rf_xlength(names);

  for (R_xlen_t pos = 0; pos < size; ++pos) {
    auto cur = Rf_translateCharUTF8(STRING_ELT(names, pos));
    if (name == cur) {
      UNPROTECT(1);
      return operator[](pos);
    }
  }

  UNPROTECT(1);
  throw std::out_of_range("r_vector");
}

#ifdef LONG_VECTOR_SUPPORT
template <typename T>
inline typename r_vector<T>::reference r_vector<T>::at(const int pos) const {
  return at(static_cast<R_xlen_t>(pos));
}
#endif

template <typename T>
inline typename r_vector<T>::reference r_vector<T>::at(const R_xlen_t pos) const {
  if (pos < 0 || pos >= length_) {
    throw std::out_of_range("r_vector");
  }
  return operator[](static_cast<R_xlen_t>(pos));
}

template <typename T>
inline typename r_vector<T>::reference r_vector<T>::at(const size_type pos) const {
  return at(static_cast<R_xlen_t>(pos));
}

template <typename T>
inline typename r_vector<T>::reference r_vector<T>::at(const r_string& name) const {
  return operator[](name);
}

template <typename T>
inline void r_vector<T>::push_back(T value) {
  while (length_ >= capacity_) {
    reserve(capacity_ == 0 ? 1 : capacity_ *= 2);
  }

  if (data_p_ != nullptr) {
    data_p_[length_] = static_cast<underlying_type>(value);
  } else {
    set_elt(data_, length_, static_cast<underlying_type>(value));
  }

  ++length_;
}

template <typename T>
inline void r_vector<T>::pop_back() {
  --length_;
}

template <typename T>
inline void r_vector<T>::resize(R_xlen_t count) {
  reserve(count);
  length_ = count;
}

/// Reserve a new capacity and copy all elements over
///
/// SAFETY: The new capacity is allowed to be smaller than the current capacity, which
/// is used in the `SEXP` conversion operator during truncation, but if that occurs then
/// we also need to update the `length_`, so if you need to truncate then you should call
/// `resize()` instead.
template <typename T>
inline void r_vector<T>::reserve(R_xlen_t new_capacity) {
  SEXP old_protect = protect_;

  data_ = (data_ == R_NilValue) ? safe[Rf_allocVector](get_sexptype(), new_capacity)
                                : reserve_data(data_, is_altrep_, new_capacity);
  protect_ = detail::store::insert(data_);
  is_altrep_ = ALTREP(data_);
  data_p_ = get_p(is_altrep_, data_);
  capacity_ = new_capacity;

  detail::store::release(old_protect);
}

template <typename T>
inline typename r_vector<T>::iterator r_vector<T>::insert(R_xlen_t pos, T value) {
  push_back(value);

  R_xlen_t i = length_ - 1;
  while (i > pos) {
    operator[](i) = (T) operator[](i - 1);
    --i;
  };
  operator[](pos) = value;

  return begin() + pos;
}

template <typename T>
inline typename r_vector<T>::iterator r_vector<T>::erase(R_xlen_t pos) {
  R_xlen_t i = pos;
  while (i < length_ - 1) {
    operator[](i) = (T) operator[](i + 1);
    ++i;
  }
  pop_back();

  return begin() + pos;
}

template <typename T>
inline void r_vector<T>::clear() {
  length_ = 0;
}

template <typename T>
CPP4R_ALWAYS_INLINE typename r_vector<T>::iterator r_vector<T>::begin() const {
#if CPP4R_HAS_CXX17
  if constexpr (traits::use_raw_pointer<T>::value) {
    return reinterpret_cast<iterator>(data_p_);
  } else {
    return generic_iterator(this, 0);
  }
#else
  return begin_impl(traits::use_raw_pointer<T>{});
#endif
}

#if !CPP4R_HAS_CXX17
template <typename T>
CPP4R_ALWAYS_INLINE
    typename r_vector<T>::iterator r_vector<T>::begin_impl(std::true_type) const {
  return reinterpret_cast<iterator>(data_p_);
}

template <typename T>
CPP4R_ALWAYS_INLINE typename r_vector<T>::iterator r_vector<T>::begin_impl(
    std::false_type) const {
  return generic_iterator(this, 0);
}
#endif

template <typename T>
CPP4R_ALWAYS_INLINE typename r_vector<T>::iterator r_vector<T>::end() const {
#if CPP4R_HAS_CXX17
  if constexpr (traits::use_raw_pointer<T>::value) {
    return reinterpret_cast<iterator>(data_p_ + length_);
  } else {
    return generic_iterator(this, length_);
  }
#else
  return end_impl(traits::use_raw_pointer<T>{});
#endif
}

#if !CPP4R_HAS_CXX17
template <typename T>
CPP4R_ALWAYS_INLINE
    typename r_vector<T>::iterator r_vector<T>::end_impl(std::true_type) const {
  return reinterpret_cast<iterator>(data_p_ + length_);
}

template <typename T>
CPP4R_ALWAYS_INLINE typename r_vector<T>::iterator r_vector<T>::end_impl(
    std::false_type) const {
  return generic_iterator(this, length_);
}
#endif

template <typename T>
inline typename r_vector<T>::iterator r_vector<T>::find(const r_string& name) const {
  SEXP names = PROTECT(this->names());
  R_xlen_t size = Rf_xlength(names);

  for (R_xlen_t pos = 0; pos < size; ++pos) {
    auto cur = Rf_translateCharUTF8(STRING_ELT(names, pos));
    if (name == cur) {
      UNPROTECT(1);
      return begin() + pos;
    }
  }

  UNPROTECT(1);
  return end();
}

#ifdef LONG_VECTOR_SUPPORT
template <typename T>
inline T r_vector<T>::value(const int pos) const {
  return value(static_cast<R_xlen_t>(pos));
}
#endif

template <typename T>
inline T r_vector<T>::value(const R_xlen_t pos) const {
  // Use the parent read-only class's operator[] which returns T directly
  return cpp4r::r_vector<T>::operator[](pos);
}

template <typename T>
inline T r_vector<T>::value(const size_type pos) const {
  return value(static_cast<R_xlen_t>(pos));
}

template <typename T>
inline attribute_proxy<r_vector<T>> r_vector<T>::attr(const char* name) const {
  return attribute_proxy<r_vector<T>>(*this, name);
}

template <typename T>
inline attribute_proxy<r_vector<T>> r_vector<T>::attr(const std::string& name) const {
  return attribute_proxy<r_vector<T>>(*this, name.c_str());
}

template <typename T>
inline attribute_proxy<r_vector<T>> r_vector<T>::attr(SEXP name) const {
  return attribute_proxy<r_vector<T>>(*this, name);
}

template <typename T>
inline attribute_proxy<r_vector<T>> r_vector<T>::names() const {
  return attribute_proxy<r_vector<T>>(*this, R_NamesSymbol);
}

template <typename T>
r_vector<T>::proxy::proxy(SEXP data, const R_xlen_t index,
                          typename r_vector::underlying_type* const p, bool is_altrep)
    : data_(data), index_(index), p_(p), is_altrep_(is_altrep) {}

template <typename T>
inline typename r_vector<T>::proxy& r_vector<T>::proxy::operator=(const proxy& rhs) {
  const underlying_type elt = rhs.get();
  set(elt);
  return *this;
}

template <typename T>
inline typename r_vector<T>::proxy& r_vector<T>::proxy::operator=(const T& rhs) {
  const underlying_type elt = static_cast<underlying_type>(rhs);
  set(elt);
  return *this;
}

template <typename T>
template <typename U>
inline typename r_vector<T>::proxy& r_vector<T>::proxy::operator=(const U& rhs) {
#if CPP4R_HAS_CXX17
  if constexpr (std::is_same<T, cpp4r::r_string>::value) {
    // Handle string assignment specially
    SEXP s = as_sexp(rhs);
    if (TYPEOF(s) == STRSXP && Rf_xlength(s) > 0) {
      s = STRING_ELT(s, 0);
    }
    SEXP char_sexp = Rf_mkCharCE(Rf_translateCharUTF8(s), CE_UTF8);
    set(char_sexp);
  } else if constexpr (std::is_same<T, cpp4r::r_complex>::value) {
    if constexpr (std::is_same<typename std::decay<U>::type,
                               std::complex<double>>::value) {
      Rcomplex c;
      c.r = rhs.real();
      c.i = rhs.imag();
      set(c);
    } else if constexpr (std::is_arithmetic<U>::value) {
      Rcomplex c;
      c.r = static_cast<double>(rhs);
      c.i = 0.0;
      set(c);
    } else {
      const underlying_type elt = static_cast<underlying_type>(rhs);
      set(elt);
    }
  } else {
    const underlying_type elt = static_cast<underlying_type>(rhs);
    set(elt);
  }
#else
  proxy_assign_dispatch(rhs, std::is_same<T, cpp4r::r_string>{},
                        std::is_same<T, cpp4r::r_complex>{});
#endif
  return *this;
}

#if !CPP4R_HAS_CXX17
// Dispatch for r_string type
template <typename T>
template <typename U>
inline void r_vector<T>::proxy::proxy_assign_dispatch(const U& rhs, std::true_type,
                                                      std::false_type) {
  SEXP s = as_sexp(rhs);
  if (TYPEOF(s) == STRSXP && Rf_xlength(s) > 0) {
    s = STRING_ELT(s, 0);
  }
  SEXP char_sexp = Rf_mkCharCE(Rf_translateCharUTF8(s), CE_UTF8);
  set(char_sexp);
}

// Dispatch for r_complex type
template <typename T>
template <typename U>
inline void r_vector<T>::proxy::proxy_assign_dispatch(const U& rhs, std::false_type,
                                                      std::true_type) {
  proxy_assign_complex(
      rhs, std::is_same<typename std::decay<U>::type, std::complex<double>>{},
      typename std::conditional<std::is_arithmetic<U>::value, std::true_type,
                                std::false_type>::type{});
}

// Dispatch for other types
template <typename T>
template <typename U>
inline void r_vector<T>::proxy::proxy_assign_dispatch(const U& rhs, std::false_type,
                                                      std::false_type) {
  const underlying_type elt = static_cast<underlying_type>(rhs);
  set(elt);
}

// Complex assignment when U is std::complex<double>
template <typename T>
template <typename U>
inline void r_vector<T>::proxy::proxy_assign_complex(const U& rhs, std::true_type,
                                                     std::false_type) {
  Rcomplex c;
  c.r = rhs.real();
  c.i = rhs.imag();
  set(c);
}

template <typename T>
template <typename U>
inline void r_vector<T>::proxy::proxy_assign_complex(const U& rhs, std::true_type,
                                                     std::true_type) {
  Rcomplex c;
  c.r = rhs.real();
  c.i = rhs.imag();
  set(c);
}

// Complex assignment when U is arithmetic (but not complex)
template <typename T>
template <typename U>
inline void r_vector<T>::proxy::proxy_assign_complex(const U& rhs, std::false_type,
                                                     std::true_type) {
  Rcomplex c;
  c.r = static_cast<double>(rhs);
  c.i = 0.0;
  set(c);
}

// Complex assignment fallback
template <typename T>
template <typename U>
inline void r_vector<T>::proxy::proxy_assign_complex(const U& rhs, std::false_type,
                                                     std::false_type) {
  const underlying_type elt = static_cast<underlying_type>(rhs);
  set(elt);
}
#endif

template <typename T>
inline typename r_vector<T>::proxy& r_vector<T>::proxy::operator+=(const T& rhs) {
  operator=(static_cast<T>(*this) + rhs);
  return *this;
}

template <typename T>
inline typename r_vector<T>::proxy& r_vector<T>::proxy::operator-=(const T& rhs) {
  operator=(static_cast<T>(*this) - rhs);
  return *this;
}

template <typename T>
inline typename r_vector<T>::proxy& r_vector<T>::proxy::operator*=(const T& rhs) {
  operator=(static_cast<T>(*this) * rhs);
  return *this;
}

template <typename T>
inline typename r_vector<T>::proxy& r_vector<T>::proxy::operator/=(const T& rhs) {
  operator=(static_cast<T>(*this) / rhs);
  return *this;
}

template <typename T>
inline typename r_vector<T>::proxy& r_vector<T>::proxy::operator++(int) {
  operator=(static_cast<T>(*this) + 1);
  return *this;
}

template <typename T>
inline typename r_vector<T>::proxy& r_vector<T>::proxy::operator--(int) {
  operator=(static_cast<T>(*this) - 1);
  return *this;
}

template <typename T>
inline void r_vector<T>::proxy::operator++() {
  operator=(static_cast<T>(*this) + 1);
}

template <typename T>
inline void r_vector<T>::proxy::operator--() {
  operator=(static_cast<T>(*this) - 1);
}

template <typename T>
inline r_vector<T>::proxy::operator T() const {
  const underlying_type elt = get();
  return static_cast<T>(elt);
}

template <typename T>
inline typename r_vector<T>::underlying_type r_vector<T>::proxy::get() const {
  if (p_ != nullptr) {
    return *p_;
  } else {
    // Handles ALTREP, VECSXP, and STRSXP cases
    return r_vector::get_elt(data_, index_);
  }
}

template <typename T>
inline void r_vector<T>::proxy::set(typename r_vector<T>::underlying_type x) {
  if (p_ != nullptr) {
    *p_ = x;
  } else {
    // Handles ALTREP, VECSXP, and STRSXP cases
    set_elt(data_, index_, x);
  }
}

template <typename T>
r_vector<T>::generic_iterator::generic_iterator(const r_vector* data, R_xlen_t pos)
    : r_vector::generic_const_iterator(data, pos) {}

template <typename T>
inline typename r_vector<T>::generic_iterator&
r_vector<T>::generic_iterator::operator++() {
  ++pos_;
  if (use_buf(data_->is_altrep()) && pos_ >= block_start_ + length_) {
    fill_buf(pos_);
  }
  return *this;
}

template <typename T>
inline typename r_vector<T>::proxy r_vector<T>::generic_iterator::operator*() const {
  if (use_buf(data_->is_altrep())) {
    return proxy(
        data_->data(), pos_,
        const_cast<typename r_vector::underlying_type*>(&buf_[pos_ - block_start_]),
        true);
  } else {
    return proxy(data_->data(), pos_,
                 data_->data_p_ != nullptr ? &data_->data_p_[pos_] : nullptr, false);
  }
}

template <typename T>
inline typename r_vector<T>::generic_iterator& r_vector<T>::generic_iterator::operator+=(
    R_xlen_t rhs) {
  pos_ += rhs;
  if (use_buf(data_->is_altrep()) && pos_ >= block_start_ + length_) {
    fill_buf(pos_);
  }
  return *this;
}

template <typename T>
inline typename r_vector<T>::generic_iterator r_vector<T>::generic_iterator::operator+(
    R_xlen_t rhs) {
  auto it = *this;
  it += rhs;
  return it;
}

/// Compared to `Rf_xlengthgets()`:
/// - This copies over attributes with `Rf_copyMostAttrib()`, which is important when we
///   truncate right before returning from the `SEXP` operator.
/// - This always allocates, even if it is the same size.
/// - This is more friendly to ALTREP `x`.
///
/// SAFETY: For use only by `reserve()`! This won't retain the `dim` or `dimnames`
/// attributes (which doesn't make much sense anyways).
template <typename T>
inline SEXP r_vector<T>::reserve_data(SEXP x, bool is_altrep, R_xlen_t size) {
  // Resize core data
  SEXP out = PROTECT(resize_data(x, is_altrep, size));

  // Resize names, if required
  // Protection seems needed to make rchk happy
  SEXP names = PROTECT(Rf_getAttrib(x, R_NamesSymbol));
  if (names != R_NilValue) {
    if (Rf_xlength(names) != size) {
      names = resize_names(names, size);
    }
    Rf_setAttrib(out, R_NamesSymbol, names);
  }

  // Copy over "most" attributes, and set OBJECT bit and S4 bit as needed.
  // Does not copy over names, dim, or dim names.
  // Names are handled already. Dim and dim names should not be applicable,
  // as this is a vector.
  // Does not look like it would ever error in our use cases, so no `safe[]`.
  Rf_copyMostAttrib(x, out);

  UNPROTECT(2);
  return out;
}

template <typename T>
inline SEXP r_vector<T>::resize_data(SEXP x, bool is_altrep, R_xlen_t size) {
  underlying_type const* v_x = get_const_p(is_altrep, x);

  SEXP out = PROTECT(safe[Rf_allocVector](get_sexptype(), size));
  underlying_type* v_out = get_p(ALTREP(out), out);

  const R_xlen_t x_size = Rf_xlength(x);
  const R_xlen_t copy_size = (x_size > size) ? size : x_size;

  // Copy over data from `x` up to `copy_size` (we could be truncating so don't blindly
  // copy everything from `x`)
  if (v_x != nullptr && v_out != nullptr) {
    std::memcpy(v_out, v_x, copy_size * sizeof(underlying_type));
  } else {
    // Handles ALTREP `x` with no const pointer, VECSXP, STRSXP
    for (R_xlen_t i = 0; i < copy_size; ++i) {
      set_elt(out, i, get_elt(x, i));
    }
  }

  UNPROTECT(1);
  return out;
}

template <typename T>
inline SEXP r_vector<T>::resize_names(SEXP x, R_xlen_t size) {
  const SEXP* v_x = STRING_PTR_RO(x);

  SEXP out = PROTECT(safe[Rf_allocVector](STRSXP, size));

  const R_xlen_t x_size = Rf_xlength(x);
  const R_xlen_t copy_size = (x_size > size) ? size : x_size;

  for (R_xlen_t i = 0; i < copy_size; ++i) {
    SET_STRING_ELT(out, i, v_x[i]);
  }

  // Ensure remaining names are initialized to `""`
  for (R_xlen_t i = copy_size; i < size; ++i) {
    SET_STRING_ELT(out, i, R_BlankString);
  }

  UNPROTECT(1);
  return out;
}

}  // namespace writable
}  // namespace cpp4r
