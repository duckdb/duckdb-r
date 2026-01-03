#pragma once

#include <initializer_list>
#include <iterator>
#include <string>

#include "cpp4r/R.hpp"
#include "cpp4r/attribute_proxy.hpp"
#include "cpp4r/cpp_version.hpp"
#include "cpp4r/r_bool.hpp"
#include "cpp4r/r_string.hpp"
#include "cpp4r/r_vector.hpp"
#include "cpp4r/sexp.hpp"

namespace cpp4r {

namespace detail {

template <typename T>
struct get_sexptype_v;
template <>
struct get_sexptype_v<double> {
  static constexpr SEXPTYPE value = REALSXP;
};
template <>
struct get_sexptype_v<int> {
  static constexpr SEXPTYPE value = INTSXP;
};
template <>
struct get_sexptype_v<r_bool> {
  static constexpr SEXPTYPE value = LGLSXP;
};
template <>
struct get_sexptype_v<r_complex> {
  static constexpr SEXPTYPE value = CPLXSXP;
};
template <>
struct get_sexptype_v<r_string> {
  static constexpr SEXPTYPE value = STRSXP;
};

// Type coercion traits - hierarchy: logical -> integer -> double -> complex
template <typename To>
struct matrix_accepts_type {
  static bool check(SEXPTYPE from) { return from == get_sexptype_v<To>::value; }
};
template <>
struct matrix_accepts_type<int> {
  static bool check(SEXPTYPE from) { return from == INTSXP || from == LGLSXP; }
};
template <>
struct matrix_accepts_type<double> {
  static bool check(SEXPTYPE from) {
    return from == REALSXP || from == INTSXP || from == LGLSXP;
  }
};
template <>
struct matrix_accepts_type<r_complex> {
  static bool check(SEXPTYPE from) {
    return from == CPLXSXP || from == REALSXP || from == INTSXP || from == LGLSXP;
  }
};

// Coerce SEXP to target type (zero-copy if already correct type)
template <typename To>
inline SEXP coerce_matrix_sexp(SEXP x) {
  SEXPTYPE from_type = r_typeof(x);
  SEXPTYPE to_type = get_sexptype_v<To>::value;

  if (from_type == to_type) return x;
  if (!matrix_accepts_type<To>::check(from_type)) throw type_error(to_type, from_type);

  SEXP result = PROTECT(Rf_coerceVector(x, to_type));
  SEXP dims = Rf_getAttrib(x, R_DimSymbol);
  if (dims != R_NilValue) Rf_setAttrib(result, R_DimSymbol, dims);
  SEXP dimnames = Rf_getAttrib(x, R_DimNamesSymbol);
  if (dimnames != R_NilValue) Rf_setAttrib(result, R_DimNamesSymbol, dimnames);
  UNPROTECT(1);
  return result;
}

}  // namespace detail

struct matrix_dims {
 protected:
  const int nrow_;
  const int ncol_;

 public:
  matrix_dims(SEXP data) : nrow_(Rf_nrows(data)), ncol_(Rf_ncols(data)) {}
  matrix_dims(int nrow, int ncol) : nrow_(nrow), ncol_(ncol) {}
  CPP4R_ALWAYS_INLINE int nrow() const noexcept { return nrow_; }
  CPP4R_ALWAYS_INLINE int ncol() const noexcept { return ncol_; }
};

struct matrix_slice {};
struct by_row : public matrix_slice {};
struct by_column : public matrix_slice {};

template <typename S>
struct matrix_slices : public matrix_dims {
  using matrix_dims::matrix_dims;
};

template <>
struct matrix_slices<by_row> : public matrix_dims {
  using matrix_dims::matrix_dims;
  CPP4R_ALWAYS_INLINE int nslices() const noexcept { return nrow(); }
  CPP4R_ALWAYS_INLINE int slice_size() const noexcept { return ncol(); }
  CPP4R_ALWAYS_INLINE int slice_stride() const noexcept { return nrow(); }
  CPP4R_ALWAYS_INLINE int slice_offset(int pos) const noexcept { return pos; }
};

template <>
struct matrix_slices<by_column> : public matrix_dims {
  using matrix_dims::matrix_dims;
  CPP4R_ALWAYS_INLINE int nslices() const noexcept { return ncol(); }
  CPP4R_ALWAYS_INLINE int slice_size() const noexcept { return nrow(); }
  CPP4R_ALWAYS_INLINE int slice_stride() const noexcept { return 1; }
  CPP4R_ALWAYS_INLINE int slice_offset(int pos) const noexcept { return pos * nrow(); }
};

template <typename V, typename T, typename S = by_column>
class matrix : public matrix_slices<S> {
  V vector_;

  template <typename V2, typename T2, typename S2>
  friend class matrix;

 public:
  using underlying_type = typename V::underlying_type;
  using scalar_type = typename V::scalar_type;

  class slice {
    const matrix& parent_;
    int index_, offset_;

   public:
    slice(const matrix& parent, int index)
        : parent_(parent), index_(index), offset_(parent.slice_offset(index)) {}

    R_xlen_t stride() const noexcept { return parent_.slice_stride(); }
    R_xlen_t size() const noexcept { return parent_.slice_size(); }
    bool operator==(const slice& rhs) const noexcept {
      return index_ == rhs.index_ && parent_.data() == rhs.parent_.data();
    }
    bool operator!=(const slice& rhs) const noexcept { return !(*this == rhs); }
    CPP4R_ALWAYS_INLINE T operator[](int pos) const {
      return parent_.vector_[offset_ + stride() * pos];
    }

    class iterator {
      const slice& slice_;
      int pos_;

     public:
      using difference_type = std::ptrdiff_t;
      using value_type = T;
      using pointer = T*;
      using reference = T&;
      using iterator_category = std::forward_iterator_tag;

      iterator(const slice& s, R_xlen_t pos) : slice_(s), pos_(pos) {}
      iterator& operator++() {
        ++pos_;
        return *this;
      }
      bool operator==(const iterator& rhs) const {
        return pos_ == rhs.pos_ && slice_ == rhs.slice_;
      }
      bool operator!=(const iterator& rhs) const { return !(*this == rhs); }
      T operator*() const { return slice_[pos_]; }
    };

    iterator begin() const { return {*this, 0}; }
    iterator end() const { return {*this, size()}; }
  };

  class slice_iterator {
    const matrix& parent_;
    int pos_;

   public:
    using difference_type = std::ptrdiff_t;
    using value_type = slice;
    using pointer = slice*;
    using reference = slice&;
    using iterator_category = std::forward_iterator_tag;

    slice_iterator(const matrix& parent, R_xlen_t pos) : parent_(parent), pos_(pos) {}
    slice_iterator& operator++() {
      ++pos_;
      return *this;
    }
    bool operator==(const slice_iterator& rhs) const {
      return pos_ == rhs.pos_ && parent_.data() == rhs.parent_.data();
    }
    bool operator!=(const slice_iterator& rhs) const { return !(*this == rhs); }
    slice operator*() { return parent_[pos_]; }
  };

  matrix(SEXP data)
      : matrix_slices<S>(data), vector_(detail::coerce_matrix_sexp<scalar_type>(data)) {}

  template <typename V2, typename T2, typename S2>
  matrix(const cpp4r::matrix<V2, T2, S2>& rhs)
      : matrix_slices<S>(rhs.nrow(), rhs.ncol()), vector_(rhs.vector_) {}

  template <typename V2, typename T2, typename S2>
  matrix(cpp4r::matrix<V2, T2, S2>&& rhs)
      : matrix_slices<S>(rhs.nrow(), rhs.ncol()), vector_(std::move(rhs.vector_)) {}

  CPP4R_ALWAYS_INLINE matrix(int nrow, int ncol)
      : matrix_slices<S>(nrow, ncol),
        vector_(Rf_allocMatrix(detail::get_sexptype_v<scalar_type>::value, nrow, ncol),
                writable::fresh_allocation_tag{}) {}

  using matrix_slices<S>::nrow;
  using matrix_slices<S>::ncol;
  using matrix_slices<S>::nslices;
  using matrix_slices<S>::slice_size;
  using matrix_slices<S>::slice_stride;
  using matrix_slices<S>::slice_offset;

  V vector() const { return vector_; }
  SEXP data() const { return vector_.data(); }
  R_xlen_t size() const { return vector_.size(); }
  operator SEXP() const { return SEXP(vector_); }

  attribute_proxy<V> attr(const char* name) { return {vector_, name}; }
  attribute_proxy<V> attr(const std::string& name) { return {vector_, name.c_str()}; }
  attribute_proxy<V> attr(SEXP name) { return {vector_, name}; }
  void attr(const char* name, SEXP value) { vector_.attr(name) = value; }
  void attr(const std::string& name, SEXP value) { vector_.attr(name) = value; }
  void attr(SEXP name, SEXP value) { vector_.attr(name) = value; }

  template <typename Name>
  void attr(Name name, std::initializer_list<SEXP> value) {
    SEXP a = PROTECT(Rf_allocVector(VECSXP, value.size()));
    int i = 0;
    for (SEXP v : value) SET_VECTOR_ELT(a, i++, v);
    vector_.attr(name) = a;
    UNPROTECT(1);
  }

  r_vector<r_string> names() const { return r_vector<r_string>(vector_.names()); }

  CPP4R_ALWAYS_INLINE const underlying_type* CPP4R_RESTRICT data_ptr() const noexcept {
    return vector_.data_ptr();
  }

  template <typename V2 = V>
  CPP4R_ALWAYS_INLINE underlying_type* CPP4R_RESTRICT data_ptr_writable() noexcept {
    return vector_.data_ptr_writable();
  }

  CPP4R_ALWAYS_INLINE T operator()(int row, int col) const {
    return vector_[row + col * nrow()];
  }

  template <typename V2 = V, typename = decltype(std::declval<V2>().data_ptr_writable())>
  CPP4R_ALWAYS_INLINE typename V2::reference operator()(int row, int col) {
    return vector_[row + col * nrow()];
  }

  slice operator[](int index) const { return {*this, index}; }
  slice_iterator begin() const { return {*this, 0}; }
  slice_iterator end() const { return {*this, nslices()}; }
};

// Read-only matrix aliases
template <typename S = by_column>
using doubles_matrix = matrix<r_vector<double>, double, S>;
template <typename S = by_column>
using integers_matrix = matrix<r_vector<int>, int, S>;
template <typename S = by_column>
using logicals_matrix = matrix<r_vector<r_bool>, r_bool, S>;
template <typename S = by_column>
using strings_matrix = matrix<r_vector<r_string>, r_string, S>;
template <typename S = by_column>
using complexes_matrix = matrix<r_vector<r_complex>, r_complex, S>;

// Writable matrix aliases
namespace writable {
template <typename S = by_column>
using doubles_matrix = matrix<r_vector<double>, typename r_vector<double>::reference, S>;
template <typename S = by_column>
using integers_matrix = matrix<r_vector<int>, typename r_vector<int>::reference, S>;
template <typename S = by_column>
using logicals_matrix = matrix<r_vector<r_bool>, typename r_vector<r_bool>::reference, S>;
template <typename S = by_column>
using strings_matrix =
    matrix<r_vector<r_string>, typename r_vector<r_string>::reference, S>;
template <typename S = by_column>
using complexes_matrix =
    matrix<r_vector<r_complex>, typename r_vector<r_complex>::reference, S>;
}  // namespace writable

}  // namespace cpp4r
