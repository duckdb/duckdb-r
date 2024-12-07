#include "signal.hpp"

#include "cpp11/R.hpp"
#include "cpp11/function.hpp"
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
	if (context) {
		instance = this;
		oldhandler = std::signal(SIGINT, ScopedInterruptHandler::signal_handler);
	}
}

ScopedInterruptHandler::~ScopedInterruptHandler() {
	Disable();
	instance = nullptr;
}

bool ScopedInterruptHandler::HandleInterrupt() const {
	// Never interrupted without context
	if (!interrupted) {
		return false;
	} else {
		D_ASSERT(context);
	}

	// This seems necessary to work around a specificity with the RStudio IDE on Windows.
	// Without the message, the interrupt is not available as a catchable condition.
	// https://github.com/krlmlr/cancel.test/issues/1
	cpp11::message("");

	// FIXME: Is this equivalent to cpp11::safe[Rf_onintrNoResume](), or worse?
	cpp11::safe[Rf_onintr]();
	return true;
}

void ScopedInterruptHandler::Disable() {
	if (context) {
		std::signal(SIGINT, oldhandler);
		context.reset();
	}
}

void ScopedInterruptHandler::signal_handler(int signum) {
	if (instance) {
		instance->interrupted = true;
		instance->context->Interrupt();
	}
}

}; // namespace duckdb
