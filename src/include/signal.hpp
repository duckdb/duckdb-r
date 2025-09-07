#pragma once

#include <csignal>

#include "duckdb/common/shared_ptr.hpp"
#include "duckdb/main/client_context.hpp"

// Toy repo: https://github.com/krlmlr/cancel.test

namespace duckdb {

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

};
