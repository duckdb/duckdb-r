#pragma once

#include "rapi.hpp"
#include "duckdb/common/progress_bar/progress_bar_display.hpp"
#include "duckdb/common/helper.hpp"

#include <thread>

// Handbook: handbook/architecture/glue/threading/README.md (which thread may run the callback)

namespace duckdb {

class RProgressBarDisplay : public ProgressBarDisplay {
public:
	RProgressBarDisplay();
	~RProgressBarDisplay() override;

	static unique_ptr<ProgressBarDisplay> Create();

public:
	void Update(double percentage) override;
	void Finish() override;

private:
	void Initialize();
	bool OnRThread() const;

private:
	// Preserved while the display lives: getOption() hands out a copy of the option's function
	// that nothing else refers to, and a streaming result keeps its display between fetches.
	SEXP progress_callback = R_NilValue;
	// The thread that built the display when its query started, which is R's.
	// A streaming result is fetched on whichever thread reads it, a thread of arrow's pool among them.
	std::thread::id r_thread;
};

} // namespace duckdb
