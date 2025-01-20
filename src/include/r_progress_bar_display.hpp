#pragma once

#include "rapi.hpp"
#include "duckdb/common/progress_bar/progress_bar_display.hpp"
#include "duckdb/common/helper.hpp"

namespace duckdb {

class RProgressBarDisplay : public ProgressBarDisplay {
public:
	RProgressBarDisplay();
	virtual ~RProgressBarDisplay() {
	}

	static unique_ptr<ProgressBarDisplay> Create();

public:
	void Update(double percentage) override;
	void Finish() override;

private:
	void Initialize();

private:
	SEXP progress_callback = R_NilValue;
};

} // namespace duckdb
