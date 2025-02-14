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

[[cpp11::register]] duckdb::conn_eptr_t rapi_connect(duckdb::db_eptr_t dual) {
	if (!dual || !dual.get()) {
		cpp11::stop("rapi_connect: Invalid database reference");
	}
	auto db = dual->get();
	if (!db || !db->db) {
		cpp11::stop("rapi_connect: Database already closed");
	}

	auto conn_wrapper = new ConnWrapper();
	conn_wrapper->conn = make_uniq<Connection>(*db->db);
	conn_wrapper->db.swap(db);

	// Set progress display config
	auto &client_context = *conn_wrapper->conn->context;
	SetDefaultConfigArguments(client_context);

	// The connection now holds a reference to the database.
	// This reference is released when the connection is closed.
	// From the R side, the database pointer will remain valid
	// as long as at least one connection to that database is open.
	dual->unlock();

	return conn_eptr_t(conn_wrapper);
}

[[cpp11::register]] void rapi_disconnect(duckdb::conn_eptr_t conn) {
	auto conn_wrapper = conn.release();
	if (conn_wrapper) {
		delete conn_wrapper;
	}
}
