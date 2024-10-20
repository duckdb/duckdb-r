#include "signal.hpp"

#include "cpp11/R.hpp"
#include "cpp11/protect.hpp"   // for safe
#include "duckdb/common/exception.hpp"

#include <R_ext/GraphicsEngine.h>

// Toy repo: https://github.com/krlmlr/cancel.test

namespace duckdb {

ScopedInterruptHandler *ScopedInterruptHandler::instance = nullptr;

ScopedInterruptHandler::ScopedInterruptHandler(shared_ptr<ClientContext> context_) : context(context_) {
	if (instance) {
		throw InternalException("ScopedInterruptHandler already active");
	}
	instance = this;
	oldhandler = std::signal(SIGINT, ScopedInterruptHandler::signal_handler);
}

ScopedInterruptHandler::~ScopedInterruptHandler() {
	std::signal(SIGINT, oldhandler);
	instance = nullptr;
}

bool ScopedInterruptHandler::HandleInterrupt() const {
	if (!interrupted) {
		return false;
	}

	// We're presumably still blocking interrupts here in the R session,
	// so this is likely equivalent to cpp11::safe[Rf_onintrNoResume]()
	cpp11::safe[Rf_onintr]();
	return true;
}

void ScopedInterruptHandler::signal_handler(int signum) {
	if (instance) {
		instance->interrupted = true;
		instance->context->Interrupt();
	}
}

}; // namespace duckdb
