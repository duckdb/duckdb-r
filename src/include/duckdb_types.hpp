#pragma once

#include "rapi.hpp"

// Silence warning about include not used directly
namespace {
using duckdb::conn_eptr_t;
}

// Avoid clash with TRUE and FALSE macros in older rtools
#undef TRUE
#undef FALSE
