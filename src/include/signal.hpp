#pragma once

#include <csignal>

#include "duckdb/common/shared_ptr.hpp"
#include "duckdb/main/client_context.hpp"

// Toy repo: https://github.com/krlmlr/cancel.test

namespace duckdb {

//! ScopedInterruptHandler serves a dual purpose:
//! 1. Install interrupt handler: Installs a signal handler to catch SIGINT
//!    and properly interrupt DuckDB operations by calling ClientContext::Interrupt()
//! 2. Avoid reentrant calls: Ensures only one ScopedInterruptHandler is active at a time,
//!    preventing deadlocks when operations are called from within signal handlers
//!    (such as progress bar callbacks). Throws "ScopedInterruptHandler already active"
//!    if instantiated while another instance is already active.
class ScopedInterruptHandler {
private:
	shared_ptr<ClientContext> context;
	bool interrupted = false;

	// oldhandler stores the old signal handler
	// so that it can be restored when the object is destroyed
	typedef void (*sig_t)(int);
	sig_t oldhandler;

	static ScopedInterruptHandler *instance;

private:
	ScopedInterruptHandler() = delete;
	ScopedInterruptHandler(const ScopedInterruptHandler &) = delete;
	ScopedInterruptHandler &operator=(const ScopedInterruptHandler &) = delete;
	ScopedInterruptHandler(ScopedInterruptHandler &&) = delete;

public:
	ScopedInterruptHandler(shared_ptr<ClientContext> context_);
	~ScopedInterruptHandler();

	void HandleInterrupt() const;
	void Disable();

private:
	static void signal_handler(int signum);
};

}; // namespace duckdb
