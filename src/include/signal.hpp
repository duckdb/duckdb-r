#pragma once

#include <csignal>

#include "duckdb/common/shared_ptr.hpp"
#include "duckdb/main/client_context.hpp"

// For Rf_onintr() needed by users of this class
#include "cpp11/R.hpp"
#include <R_ext/GraphicsEngine.h>

namespace duckdb {

class ScopedInterruptHandler {
private:
	shared_ptr<ClientContext> context;
	bool interrupted = false;

	// oldhandler stores the old signal handler
	// so that it can be restored when the object is destroyed
	sig_t oldhandler;

	static ScopedInterruptHandler *instance;

public:
	ScopedInterruptHandler(shared_ptr<ClientContext> context_);
	~ScopedInterruptHandler();

	bool WasInterrupted() const;

private:
	static void signal_handler(int signum);
};

};
