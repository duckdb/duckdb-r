//===----------------------------------------------------------------------===//
//                         DuckDB
//
// duckdb/common/optional_idx.hpp
//
//
//===----------------------------------------------------------------------===//

#pragma once

#include "duckdb/common/exception.hpp"
#include "duckdb/common/optional.hpp"

namespace duckdb {

class optional_idx {
public:
	constexpr optional_idx() {
	}
	// NOLINTNEXTLINE: allow implicit conversion from idx_t
	constexpr optional_idx(idx_t index_p) : index(index_p), valid(true) {
	}

	static optional_idx Invalid() {
		return optional_idx();
	}

	bool IsValid() const {
		return valid;
	}

	void SetInvalid() {
		index = 0;
		valid = false;
	}

	idx_t GetIndex() const {
		if (!valid) {
			ThrowNotSet();
		}
		return index;
	}

	inline bool operator==(const optional_idx &rhs) const {
		return valid == rhs.valid && (!valid || index == rhs.index);
	}

	inline bool operator!=(const optional_idx &rhs) const {
		return !(*this == rhs);
	}

private:
	//! Kept out-of-line so that the throwing path does not block inlining of the accessors
	[[noreturn]] DUCKDB_API static void ThrowNotSet();

private:
	//! Not std::optional: the index stays initialized while unset, since compilers may read it before the flag
	idx_t index = 0;
	bool valid = false;
};

} // namespace duckdb
