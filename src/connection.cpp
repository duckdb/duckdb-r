#include "cpp11/environment.hpp"
#include "rapi.hpp"
#include "r_progress_bar_display.hpp"
#include "duckdb/main/client_context.hpp"

using namespace duckdb;

void duckdb::ConnDeleter(ConnWrapper *conn) {
	cpp11::warning("Connection is garbage-collected, use dbDisconnect() to avoid this.");
	delete conn;
}

unique_ptr<ProgressBarDisplay> RProgressBarDisplay::Create() {
	return make_uniq<RProgressBarDisplay>();
}

void RProgressBarDisplay::Initialize() {
	cpp11::function getNamespace = RStrings::get().getNamespace_sym;
	cpp11::environment duckdb_namespace(getNamespace(RStrings::get().duckdb_str));
	cpp11::sexp get_progress_display(Rf_lang1(RStrings::get().get_progress_display_sym));
	auto progress_display = cpp11::safe[Rf_eval](get_progress_display, duckdb_namespace);

	if (Rf_isFunction(progress_display)) {
		progress_callback = progress_display;
	}
}

RProgressBarDisplay::RProgressBarDisplay() : ProgressBarDisplay() {
	Initialize();
}

void RProgressBarDisplay::Update(double percentage) {
	if (progress_callback == R_NilValue) {
		return;
	}

	try {
		cpp11::sexp call = Rf_lang2(progress_callback, Rf_ScalarReal(percentage));
		cpp11::safe[Rf_eval](call, R_BaseEnv);
	} catch (std::exception &e) {
		// Ignore progress bar error
	}
}

void RProgressBarDisplay::Finish() {
	Update(100);
}

static void SetDefaultConfigArguments(ClientContext &context) {
	auto &config = ClientConfig::GetConfig(context);
	// Set the function used to create the display for the progress bar
	config.display_create_func = RProgressBarDisplay::Create;
	config.enable_progress_bar = true;
	config.wait_time = 0;
}

[[cpp11::register]] duckdb::conn_eptr_t rapi_connect(duckdb::db_eptr_t dual, duckdb::ConvertOpts convert_opts) {
	if (!dual || !dual.get()) {
		rapi_error_with_context("rapi_connect", "Invalid database reference");
	}
	auto db = dual->get();
	if (!db || !db->db) {
		rapi_error_with_context("rapi_connect", "Database already closed");
	}

	auto conn_wrapper = make_uniq<ConnWrapper>(std::move(db), std::move(convert_opts));

	// Set progress display config
	auto &client_context = *conn_wrapper->conn->context;
	SetDefaultConfigArguments(client_context);

	// The connection now holds a reference to the database.
	// This reference is released when the connection is closed.
	// From the R side, the database pointer will remain valid
	// as long as at least one connection to that database is open.
	dual->unlock();

	return conn_eptr_t(conn_wrapper.release());
}

[[cpp11::register]] void rapi_disconnect(duckdb::conn_eptr_t conn) {
	auto conn_wrapper = conn.release();
	if (conn_wrapper) {
		delete conn_wrapper;
	}
}

[[cpp11::register]] bool rapi_connection_valid(duckdb::conn_eptr_t conn) {
	// Check connection validity without acquiring ClientContext locks
	// This avoids the "ScopedInterruptHandler already active" issue when
	// called from progress bar handlers or other contexts that already
	// have interrupt protection
	if (!conn || !conn.get()) {
		return false;
	}

	auto conn_wrapper = conn.get();
	if (!conn_wrapper) {
		return false;
	}

	// Check if the connection object exists
	if (!conn_wrapper->conn) {
		return false;
	}

	// Check if the database wrapper is still valid
	if (!conn_wrapper->db || !conn_wrapper->db->db) {
		return false;
	}

	// All checks passed - connection appears valid
	return true;
}
