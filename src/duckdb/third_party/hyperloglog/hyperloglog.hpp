//===----------------------------------------------------------------------===//
//                         DuckDB
//
// third_party/hyperloglog/hyperloglog.hpp
//
//
//===----------------------------------------------------------------------===//

#pragma once

#include <stdint.h>
#include <string.h>

namespace duckdb_hll {

// NOLINTBEGIN

/* Error codes */
#define HLL_C_OK  0
#define HLL_C_ERR -1

struct robj {
	void *ptr;
};

//! Create a new empty HyperLogLog object
robj *hll_create(void);
//! Convert hll from sparse to dense
int hllSparseToDense(robj *o);
//! Destroy the specified HyperLogLog object
void hll_destroy(robj *obj);
//! Add an element with the specified amount of bytes to the HyperLogLog. Returns C_ERR on failure, otherwise returns 0
//! if the cardinality did not change, and 1 otherwise.
int hll_add(robj *o, unsigned char *ele, size_t elesize);
//! Returns the estimated amount of unique elements seen by the HyperLogLog. Returns C_OK on success, or C_ERR on
//! failure.
int hll_count(robj *o, size_t *result);
//! Merge hll_count HyperLogLog objects into a single one. Returns NULL on failure, or the new HLL object on success.
robj *hll_merge(robj **hlls, size_t hll_count);
//! Get size (in bytes) of the HLL
uint64_t get_size();
//! Get the number of registers
uint64_t num_registers();
//! The maximum number of trailing zeros
uint8_t maximum_zeros();
//! Get the count of the register
uint8_t get_register(robj *o, size_t index);
//! Set the count of the register
void set_register(robj *o, size_t index, uint8_t count);

// NOLINTEND

} // namespace duckdb_hll

namespace duckdb {

void AddToLogsInternal(UnifiedVectorFormat &vdata, idx_t count, uint64_t indices[], uint8_t counts[], void ***logs[],
                       const SelectionVector *log_sel);

void AddToSingleLogInternal(UnifiedVectorFormat &vdata, idx_t count, uint64_t indices[], uint8_t counts[], void *log);

} // namespace duckdb
