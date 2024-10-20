#include "signal.hpp"

namespace duckdb {

ScopedInterruptHandler *ScopedInterruptHandler::instance = nullptr;

ScopedInterruptHandler::ScopedInterruptHandler(shared_ptr<ClientContext> context_) : context(context_) {
	instance = this;
	oldhandler = std::signal(SIGINT, ScopedInterruptHandler::signal_handler);
}

ScopedInterruptHandler::~ScopedInterruptHandler() {
	std::signal(SIGINT, oldhandler);
	instance = nullptr;
}

bool ScopedInterruptHandler::WasInterrupted() const {
	return interrupted;
}

void ScopedInterruptHandler::signal_handler(int signum) {
	if (instance) {
		instance->interrupted = true;
		instance->context->Interrupt();
	}
}

};
