#pragma once

#include <stddef.h>  // for ptrdiff_t, size_t

#include <algorithm>         // for max
#include <array>             // for array
#include <cstdio>            // for snprintf
#include <cstring>           // for memcpy
#include <exception>         // for exception
#include <initializer_list>  // for initializer_list
#include <iterator>          // for forward_iterator_tag
#include <stdexcept>         // for out_of_range
#include <string>            // for string, basic_string
#include <type_traits>       // for decay, is_same, and enable_if
#include <utility>           // for declval

#include "cpp4r/R.hpp"                // for R’s C interface (e.g., for SEXP)
#include "cpp4r/attribute_proxy.hpp"  // for attribute_proxy
#include "cpp4r/named_arg.hpp"        // for named_arg
#include "cpp4r/protect.hpp"          // for store
#include "cpp4r/r_complex.hpp"        // for r_complex
#include "cpp4r/r_string.hpp"         // for r_string
#include "cpp4r/sexp.hpp"             // for sexp

namespace cpp4r {

using namespace cpp4r::literals;

namespace traits {
// By default, types don't use raw pointer iterators
template <typename T>
struct use_raw_pointer : std::false_type {};

// Specialize for primitive numeric types that can use raw pointer iterators
// This enables Rcpp-style direct pointer access for maximum performance
template <>
struct use_raw_pointer<double> : std::true_type {};
template <>
struct use_raw_pointer<int> : std::true_type {};
// Note: r_bool, r_string, r_complex, and list types still need generic iterators
// because they require special handling (proxies, ALTREP awareness, etc.)
}  // namespace traits

namespace writable {
template <typename T>
class r_vector;
}  // namespace writable

// Declarations
template <typename T>
class r_vector {
 public:
  // Forward declare
  class generic_const_iterator;
  using underlying_type = typename traits::get_underlying_type<T>::type;

  // Expose scalar type for template metaprogramming (e.g. matrix allocation)
  using scalar_type = T;

 private:
  // Memory layout optimized for cache locality in hot paths:
  // - data_, data_p_, length_ are accessed together in operator[] and iterators
  // - protect_ and is_altrep_ are accessed less frequently
  SEXP data_ = R_NilValue;
  underlying_type* data_p_ = nullptr;  // Frequently accessed with data_
  R_xlen_t length_ = 0;                // Frequently accessed with data_p_
  SEXP protect_ = R_NilValue;          // Less frequently accessed
  bool is_altrep_ = false;             // Rarely accessed in hot paths

 public:
  typedef ptrdiff_t difference_type;
  typedef size_t size_type;
  typedef T value_type;
  typedef T* pointer;
  typedef T& reference;

  ~r_vector();

  r_vector() noexcept = default;
  r_vector(SEXP data);
  r_vector(SEXP data, bool is_altrep);
  r_vector(const r_vector& x);
  r_vector(r_vector<T>&& x);
  r_vector(const writable::r_vector<T>& x);

  r_vector& operator=(const r_vector& rhs);
  r_vector& operator=(r_vector&& rhs);

  operator SEXP() const;
  operator sexp() const;

#ifdef LONG_VECTOR_SUPPORT
  T operator[](const int pos) const;
#endif
  T operator[](const R_xlen_t pos) const;
  T operator[](const size_type pos) const;
  T operator[](const r_string& name) const;

#ifdef LONG_VECTOR_SUPPORT
  T at(const int pos) const;
#endif
  T at(const R_xlen_t pos) const;
  T at(const size_type pos) const;
  T at(const r_string& name) const;

  bool contains(const r_string& name) const;
  bool is_altrep() const;
  bool named() const;
  R_xlen_t size() const;
  bool empty() const;
  SEXP data() const;

  // Fast-path pointer accessor to avoid REAL(data()) overhead in tight loops
  // Returns nullptr for ALTREP or writable vectors - use data_p_ field for those cases
  CPP4R_ALWAYS_INLINE const underlying_type* CPP4R_RESTRICT data_ptr() const noexcept {
    return data_p_;
  }

  const sexp attr(const char* name) const;
  const sexp attr(const std::string& name) const;
  const sexp attr(SEXP name) const;

  r_vector<r_string> names() const;

  class generic_const_iterator {
    // Iterator references:
    // https://cplusplus.com/reference/iterator/
    // https://stackoverflow.com/questions/8054273/how-to-implement-an-stl-style-iterator-and-avoid-common-pitfalls
    // It seems like our iterator doesn't fully implement everything for
    // `random_access_iterator_tag` (like an `[]` operator, for example). If we discover
    // issues with it, we probably need to add more methods.
   private:
    const r_vector* data_;
    R_xlen_t pos_;
    // Buffer used for ALTREP region reads. Keep this small to avoid large
    // stack frames for iterator objects. Tunable via BUF_CAP.
    static constexpr std::size_t BUF_CAP = 64;
    // Don't attempt ALTREP region buffering for tiny vectors (cheap per-elt
    // access is preferable). Tunable threshold.
    static constexpr R_xlen_t BUF_THRESHOLD = static_cast<R_xlen_t>(256);
    std::array<underlying_type, BUF_CAP> buf_;
    R_xlen_t block_start_ = 0;
    R_xlen_t length_ = 0;

   public:
    using difference_type = ptrdiff_t;
    using value_type = T;
    using pointer = T*;
    using reference = T&;
    using iterator_category = std::random_access_iterator_tag;

    generic_const_iterator(const r_vector* data, R_xlen_t pos);

    generic_const_iterator operator+(R_xlen_t pos);
    ptrdiff_t operator-(const generic_const_iterator& other) const;

    generic_const_iterator& operator++();
    generic_const_iterator& operator--();

    generic_const_iterator& operator+=(R_xlen_t pos);
    generic_const_iterator& operator-=(R_xlen_t pos);

    bool operator!=(const generic_const_iterator& other) const;
    bool operator==(const generic_const_iterator& other) const;

    T operator*() const;

    friend class writable::r_vector<T>;

   private:
    // Implemented in specialization
    static bool use_buf(bool is_altrep);
    void fill_buf(R_xlen_t pos);
  };

  using const_iterator =
      typename std::conditional<traits::use_raw_pointer<T>::value, const T*,
                                generic_const_iterator>::type;

  const_iterator begin() const;
  const_iterator end() const;
  const_iterator cbegin() const;
  const_iterator cend() const;
  const_iterator find(const r_string& name) const;
  // Overload: use a pre-translated names cache for faster lookups (opt-in)
  const_iterator find(const std::vector<std::string>& names_cache,
                      const r_string& name) const;
  // Fast-path find using a pre-translated names vector (opt-in).
  const_iterator find_cached(const std::vector<std::string>& names_cache,
                             const r_string& name) const;

 private:
#if !CPP4R_HAS_CXX17
  // C++11/14 fallback helpers for begin/end
  const_iterator begin_impl(std::true_type) const;
  const_iterator begin_impl(std::false_type) const;
  const_iterator end_impl(std::true_type) const;
  const_iterator end_impl(std::false_type) const;
#endif

  // Implemented in specialization
  static underlying_type get_elt(SEXP x, R_xlen_t i);
  // Implemented in specialization
  static underlying_type* get_p(bool is_altrep, SEXP data);
  // Implemented in specialization
  static underlying_type const* get_const_p(bool is_altrep, SEXP data);
  // Implemented in specialization
  static void get_region(SEXP x, R_xlen_t i, R_xlen_t n, underlying_type* buf);
  // Implemented in specialization
  static SEXPTYPE get_sexptype();
  // Implemented in specialization (throws by default, specialization in list type)
  static T get_oob();
  static SEXP valid_type(SEXP x);
  static SEXP valid_length(SEXP x, R_xlen_t n);

  friend class writable::r_vector<T>;
};

namespace writable {

template <typename T>
using has_begin_fun = std::decay<decltype(*begin(std::declval<T>()))>;

// Tag type for fast-path constructor (freshly allocated, non-ALTREP data)
struct fresh_allocation_tag {};

// Read/write access to new or copied r_vectors
template <typename T>
class r_vector : public cpp4r::r_vector<T> {
 public:
  // Forward declare
  class proxy;
  class generic_iterator;

  using typename cpp4r::r_vector<T>::underlying_type;

 private:
  R_xlen_t capacity_ = 0;

  using cpp4r::r_vector<T>::data_;
  using cpp4r::r_vector<T>::data_p_;
  using cpp4r::r_vector<T>::is_altrep_;
  using cpp4r::r_vector<T>::length_;
  using cpp4r::r_vector<T>::protect_;

  friend class cpp4r::r_vector<T>;

 public:
  typedef ptrdiff_t difference_type;
  typedef size_t size_type;

  using reference =
      typename std::conditional<traits::use_raw_pointer<T>::value, T&, proxy>::type;

  using value_type =
      typename std::conditional<traits::use_raw_pointer<T>::value, T, proxy>::type;

  typedef value_type* pointer;

  r_vector() noexcept = default;
  r_vector(const SEXP& data);
  r_vector(SEXP&& data);
  r_vector(const SEXP& data, bool is_altrep);
  r_vector(SEXP&& data, bool is_altrep);
  r_vector(const r_vector& rhs);
  r_vector(r_vector&& rhs);
  r_vector(const cpp4r::r_vector<T>& rhs);
  r_vector(std::initializer_list<T> il);
  explicit r_vector(std::initializer_list<named_arg> il);

  // Fast-path constructor for freshly allocated data (non-ALTREP, owned)
  // This bypasses type validation and ALTREP checks for maximum performance
  r_vector(SEXP data, fresh_allocation_tag);

  explicit r_vector(const R_xlen_t size);

  template <typename Iter>
  r_vector(Iter first, Iter last);

  template <typename V, typename W = has_begin_fun<V>>
  r_vector(const V& obj);

  r_vector& operator=(const r_vector& rhs);
  r_vector& operator=(r_vector&& rhs);

  operator SEXP() const;

#ifdef LONG_VECTOR_SUPPORT
  reference operator[](const int pos) const;
#endif
  reference operator[](const R_xlen_t pos) const;
  reference operator[](const size_type pos) const;
  reference operator[](const r_string& name) const;

#ifdef LONG_VECTOR_SUPPORT
  reference at(const int pos) const;
#endif
  reference at(const R_xlen_t pos) const;
  reference at(const size_type pos) const;
  reference at(const r_string& name) const;

  void push_back(T value);
  template <typename U = T,
            typename std::enable_if<std::is_same<U, r_string>::value>::type* = nullptr>
  void push_back(const std::string& value);  // Pacha: r_string only (#406)
  void push_back(const named_arg& value);
  void pop_back();

  void resize(R_xlen_t count);
  void reserve(R_xlen_t new_capacity);

  // iterator insert(R_xlen_t pos, T value); // Return type depends on iterator
  // iterator erase(R_xlen_t pos);

  void clear();

  class generic_iterator : public cpp4r::r_vector<T>::generic_const_iterator {
   private:
    using cpp4r::r_vector<T>::generic_const_iterator::data_;
    using cpp4r::r_vector<T>::generic_const_iterator::block_start_;
    using cpp4r::r_vector<T>::generic_const_iterator::pos_;
    using cpp4r::r_vector<T>::generic_const_iterator::buf_;
    using cpp4r::r_vector<T>::generic_const_iterator::length_;
    using cpp4r::r_vector<T>::generic_const_iterator::use_buf;
    using cpp4r::r_vector<T>::generic_const_iterator::fill_buf;

   public:
    using difference_type = ptrdiff_t;
    using value_type = proxy;
    using pointer = proxy*;
    using reference = proxy&;
    using iterator_category = std::forward_iterator_tag;

    generic_iterator(const r_vector* data, R_xlen_t pos);

    generic_iterator& operator++();

    proxy operator*() const;

    using cpp4r::r_vector<T>::generic_const_iterator::operator!=;

    generic_iterator& operator+=(R_xlen_t rhs);
    generic_iterator operator+(R_xlen_t rhs);
  };

  using iterator = typename std::conditional<traits::use_raw_pointer<T>::value, T*,
                                             generic_iterator>::type;

  iterator insert(R_xlen_t pos, T value);
  iterator erase(R_xlen_t pos);

  iterator begin() const;
  iterator end() const;

#if !CPP4R_HAS_CXX17
  // C++11/14 fallback helpers
  iterator begin_impl(std::true_type) const;
  iterator begin_impl(std::false_type) const;
  iterator end_impl(std::true_type) const;
  iterator end_impl(std::false_type) const;
  reference subscript_impl(const R_xlen_t pos, std::true_type) const;
  reference subscript_impl(const R_xlen_t pos, std::false_type) const;
  void named_arg_assign_elt(R_xlen_t i, underlying_type elt, std::true_type);
  void named_arg_assign_elt(R_xlen_t i, underlying_type elt, std::false_type);
#endif

  using cpp4r::r_vector<T>::cbegin;
  using cpp4r::r_vector<T>::cend;
  using cpp4r::r_vector<T>::size;

  // Fast-path pointer accessor for writable vectors
  // Returns nullptr for ALTREP vectors
  CPP4R_ALWAYS_INLINE underlying_type* CPP4R_RESTRICT data_ptr_writable() noexcept {
    return data_p_;
  }

  CPP4R_ALWAYS_INLINE const underlying_type* CPP4R_RESTRICT data_ptr() const noexcept {
    return data_p_;
  }

  iterator find(const r_string& name) const;
  // Overload: use a pre-translated names cache for faster lookups (opt-in)
  iterator find(const std::vector<std::string>& names_cache, const r_string& name) const;
  // Fast-path find using a pre-translated names vector (opt-in).
  iterator find_cached(const std::vector<std::string>& names_cache,
                       const r_string& name) const;

  // Get the value at position without returning a proxy
  // This is useful when you need the actual value (e.g., for C-style printf functions)
  // that don't trigger implicit conversions from proxy types
#ifdef LONG_VECTOR_SUPPORT
  T value(const int pos) const;
#endif
  T value(const R_xlen_t pos) const;
  T value(const size_type pos) const;

  attribute_proxy<r_vector<T>> attr(const char* name) const;
  attribute_proxy<r_vector<T>> attr(const std::string& name) const;
  attribute_proxy<r_vector<T>> attr(SEXP name) const;

  attribute_proxy<r_vector<T>> names() const;

  // Implemented in specialization
  static void set_elt(SEXP x, R_xlen_t i, underlying_type value);

  class proxy {
   private:
    const SEXP data_;
    const R_xlen_t index_;
    underlying_type* const p_;
    bool is_altrep_;

   public:
    proxy(SEXP data, const R_xlen_t index, underlying_type* const p, bool is_altrep);

    proxy& operator=(const proxy& rhs);

    proxy& operator=(const T& rhs);

    template <typename U>
    proxy& operator=(const U& rhs);

    proxy& operator+=(const T& rhs);
    proxy& operator-=(const T& rhs);
    proxy& operator*=(const T& rhs);
    proxy& operator/=(const T& rhs);
    proxy& operator++(int);
    proxy& operator--(int);

    void operator++();
    void operator--();

    operator T() const;

   private:
    underlying_type get() const;
    void set(underlying_type x);

#if !CPP4R_HAS_CXX17
    // C++11/14 fallback helpers for templated operator=
    template <typename U>
    void proxy_assign_dispatch(const U& rhs, std::true_type,
                               std::false_type);  // r_string
    template <typename U>
    void proxy_assign_dispatch(const U& rhs, std::false_type,
                               std::true_type);  // r_complex
    template <typename U>
    void proxy_assign_dispatch(const U& rhs, std::false_type, std::false_type);  // other
    template <typename U>
    void proxy_assign_complex(const U& rhs, std::true_type,
                              std::false_type);  // complex<double>
    template <typename U>
    void proxy_assign_complex(const U& rhs, std::true_type,
                              std::true_type);  // complex<double> && arithmetic
    template <typename U>
    void proxy_assign_complex(const U& rhs, std::false_type,
                              std::true_type);  // arithmetic
    template <typename U>
    void proxy_assign_complex(const U& rhs, std::false_type, std::false_type);  // other
#endif
  };

 private:
  static SEXP reserve_data(SEXP x, bool is_altrep, R_xlen_t size);
  static SEXP resize_data(SEXP x, bool is_altrep, R_xlen_t size);
  static SEXP resize_names(SEXP x, R_xlen_t size);

  using cpp4r::r_vector<T>::get_elt;
  using cpp4r::r_vector<T>::get_p;
  using cpp4r::r_vector<T>::get_const_p;
  using cpp4r::r_vector<T>::get_sexptype;
  using cpp4r::r_vector<T>::valid_type;
  using cpp4r::r_vector<T>::valid_length;
};
}  // namespace writable

class type_error : public std::exception {
 public:
  type_error(SEXPTYPE expected, SEXPTYPE actual) : expected_(expected), actual_(actual) {}
  virtual const char* what() const noexcept override {
    snprintf(str_, 64, "Invalid input type, expected '%s' actual '%s'",
             Rf_type2char(expected_), Rf_type2char(actual_));
    return str_;
  }

 private:
  SEXPTYPE expected_;
  SEXPTYPE actual_;
  mutable char str_[64];
};

// Helper type traits for as_cpp conversions
template <typename C, typename T = typename std::decay<C>::type::value_type>
using is_vector_of_strings = typename std::enable_if<
    std::is_same<typename std::decay<T>::type, std::string>::value,
    typename std::decay<C>::type>::type;

}  // namespace cpp4r
