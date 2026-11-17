// Opens a missing file through the engine's FileSystem with
// FILE_FLAGS_NULL_IF_NOT_EXISTS and a caching mode, and reports whether the
// call returns the null handle the flag promises.
// The record it serves is the README.md beside this file.
//
// Usage: repro <path> <always|remote|none> [SQL statement]...
// Each SQL statement runs first, on the same connection (LOAD httpfs, a secret).

#include "duckdb.hpp"
#include "duckdb/common/file_system.hpp"

#include <cstdio>
#include <cstdlib>
#include <cstring>

using namespace duckdb;

// The first line of an error, or with REPRO_TRACE set, the whole of it,
// including the stack trace the engine appends to an internal error.
static string FirstLine(std::exception &ex) {
	auto message = ErrorData(ex).Message();
	if (getenv("REPRO_TRACE")) {
		return message;
	}
	return message.substr(0, message.find('\n'));
}

static bool ParseMode(const char *mode, CachingMode &result) {
	if (strcmp(mode, "always") == 0) {
		result = CachingMode::ALWAYS_CACHE;
	} else if (strcmp(mode, "remote") == 0) {
		result = CachingMode::CACHE_REMOTE_ONLY;
	} else if (strcmp(mode, "none") == 0) {
		result = CachingMode::NO_CACHING;
	} else {
		return false;
	}
	return true;
}

int main(int argc, char **argv) {
	if (argc < 3) {
		fprintf(stderr, "usage: %s <path> <always|remote|none> [SQL statement]...\n", argv[0]);
		return 2;
	}
	const string path = argv[1];
	const char *mode = argv[2];
	CachingMode caching_mode;
	if (!ParseMode(mode, caching_mode)) {
		fprintf(stderr, "unknown caching mode: %s\n", mode);
		return 2;
	}
	printf("engine: %s %s\n", DuckDB::LibraryVersion(), DuckDB::SourceID());

	DuckDB db(nullptr);
	Connection con(db);
	for (int i = 3; i < argc; i++) {
		auto result = con.Query(argv[i]);
		if (result->HasError()) {
			printf("setup failed: %s: %s\n", argv[i], result->GetError().c_str());
			return 1;
		}
	}

	auto loaded = con.Query("SELECT extension_name || ' ' || extension_version FROM duckdb_extensions() "
	                        "WHERE loaded AND install_mode::VARCHAR <> 'STATICALLY_LINKED' ORDER BY ALL");
	while (auto chunk = loaded->Fetch()) {
		for (idx_t row = 0; row < chunk->size(); row++) {
			printf("loaded: %s\n", chunk->GetValue(0, row).ToString().c_str());
		}
	}

	FileOpenFlags flags(FileFlags::FILE_FLAGS_READ | FileFlags::FILE_FLAGS_DIRECT_IO |
	                    FileFlags::FILE_FLAGS_NULL_IF_NOT_EXISTS);
	flags.SetCachingMode(caching_mode);
	printf("open: %s, caching mode %s\n", path.c_str(), mode);

	int status = 0;
	con.context->RunFunctionInTransaction([&]() {
		auto &fs = FileSystem::GetFileSystem(*con.context);
		unique_ptr<FileHandle> handle;
		try {
			handle = fs.OpenFile(path, flags);
		} catch (std::exception &ex) {
			printf("OpenFile threw: %s\n", FirstLine(ex).c_str());
			status = 1;
			return;
		}
		if (!handle) {
			printf("OpenFile returned: null handle\n");
			return;
		}
		printf("OpenFile returned: non-null handle\n");
		try {
			auto size = handle->GetFileSize();
			printf("GetFileSize returned: %lld\n", (long long)size);
		} catch (std::exception &ex) {
			printf("GetFileSize threw: %s\n", FirstLine(ex).c_str());
			status = 1;
		}
	});
	return status;
}
