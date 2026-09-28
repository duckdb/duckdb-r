/*
 * Throwaway probe for the draft pull request duckdb/duckdb-r#2854, not meant
 * to merge: how Windows and the C runtime see a symlink whose target does not
 * exist yet, call by call, as the engine's LocalFileSystem makes them.
 * Handbook: handbook/usage/connections/README.md
 */
#if !defined(_WIN32_WINNT) || _WIN32_WINNT < 0x0600
#undef _WIN32_WINNT
#define _WIN32_WINNT 0x0600
#endif
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <winioctl.h>
#include <io.h>
#include <sys/stat.h>
#include <errno.h>
#include <stdio.h>
#include <string.h>
#define STRICT_R_HEADERS
#include <R.h>

typedef struct {
	ULONG ReparseTag;
	USHORT ReparseDataLength;
	USHORT Reserved;
	USHORT SubstituteNameOffset;
	USHORT SubstituteNameLength;
	USHORT PrintNameOffset;
	USHORT PrintNameLength;
	ULONG Flags;
	WCHAR PathBuffer[1];
} probe_symlink_reparse;

static ULONG reparse_buffer[16 * 1024 / sizeof(ULONG)];

static wchar_t *widen(const char *s) {
	int n = MultiByteToWideChar(CP_UTF8, 0, s, -1, NULL, 0);
	wchar_t *w = (wchar_t *)R_alloc(n, sizeof(wchar_t));
	MultiByteToWideChar(CP_UTF8, 0, s, -1, w, n);
	return w;
}

static const char *narrow(const wchar_t *w, int len) {
	int n = WideCharToMultiByte(CP_UTF8, 0, w, len, NULL, 0, NULL, NULL);
	char *s = R_alloc(n + 1, 1);
	WideCharToMultiByte(CP_UTF8, 0, w, len, s, n, NULL, NULL);
	s[n] = 0;
	return s;
}

static const char *error_name(DWORD code) {
	switch (code) {
	case 0:
		return "0 (none)";
	case ERROR_FILE_NOT_FOUND:
		return "2 ERROR_FILE_NOT_FOUND";
	case ERROR_PATH_NOT_FOUND:
		return "3 ERROR_PATH_NOT_FOUND";
	case ERROR_ACCESS_DENIED:
		return "5 ERROR_ACCESS_DENIED";
	case ERROR_SHARING_VIOLATION:
		return "32 ERROR_SHARING_VIOLATION";
	case ERROR_FILE_EXISTS:
		return "80 ERROR_FILE_EXISTS";
	case ERROR_INVALID_NAME:
		return "123 ERROR_INVALID_NAME";
	case ERROR_ALREADY_EXISTS:
		return "183 ERROR_ALREADY_EXISTS";
	case ERROR_CANT_ACCESS_FILE:
		return "1920 ERROR_CANT_ACCESS_FILE";
	case ERROR_CANT_RESOLVE_FILENAME:
		return "1921 ERROR_CANT_RESOLVE_FILENAME";
	case ERROR_NOT_A_REPARSE_POINT:
		return "4390 ERROR_NOT_A_REPARSE_POINT";
	default: {
		char *s = R_alloc(32, 1);
		snprintf(s, 32, "%lu", (unsigned long)code);
		return s;
	}
	}
}

static const char *disposition_name(DWORD d) {
	switch (d) {
	case CREATE_NEW:
		return "CREATE_NEW";
	case CREATE_ALWAYS:
		return "CREATE_ALWAYS";
	case OPEN_EXISTING:
		return "OPEN_EXISTING";
	case OPEN_ALWAYS:
		return "OPEN_ALWAYS";
	case TRUNCATE_EXISTING:
		return "TRUNCATE_EXISTING";
	default:
		return "?";
	}
}

static void print_final_path(HANDLE h) {
	wchar_t final_path[2048];
	DWORD n = GetFinalPathNameByHandleW(h, final_path, 2048, FILE_NAME_NORMALIZED);
	if (n == 0 || n >= 2048) {
		Rprintf("    final path: (unavailable, error %s)\n", error_name(GetLastError()));
	} else {
		Rprintf("    final path: %s\n", narrow(final_path, (int)n));
	}
}

/* The calls LocalFileSystem::FileExists() makes on Windows, in its order. */
void probe_view(char **path) {
	const wchar_t *w = widen(path[0]);

	DWORD attr = GetFileAttributesW(w);
	if (attr == INVALID_FILE_ATTRIBUTES) {
		Rprintf("    GetFileAttributesW: INVALID_FILE_ATTRIBUTES (error %s)\n", error_name(GetLastError()));
	} else {
		Rprintf("    GetFileAttributesW: 0x%lx%s%s\n", (unsigned long)attr,
		        (attr & FILE_ATTRIBUTE_REPARSE_POINT) ? " REPARSE_POINT" : "",
		        (attr & FILE_ATTRIBUTE_DIRECTORY) ? " DIRECTORY" : "");
	}

	errno = 0;
	int acc = _waccess(w, 0);
	int acc_errno = errno;
	Rprintf("    _waccess(path, 0): %d (errno %d)\n", acc, acc ? acc_errno : 0);

	struct _stati64 st;
	memset(&st, 0xA5, sizeof st);
	errno = 0;
	int rc = _wstati64(w, &st);
	int st_errno = errno;
	unsigned mode = (unsigned)st.st_mode;
	Rprintf("    _wstati64(path): %d (errno %d), st_mode 0x%04x%s: S_IFREG %d, S_IFDIR %d, _S_IFCHR %d\n", rc,
	        rc ? st_errno : 0, mode, mode == 0xA5A5 ? " (the sentinel, untouched)" : "", (mode & S_IFREG) ? 1 : 0,
	        (mode & S_IFDIR) ? 1 : 0, (mode & _S_IFCHR) ? 1 : 0);
	Rprintf("    FileExists() as the engine computes it: %s\n", (acc == 0 && (st.st_mode & S_IFREG)) ? "TRUE" : "FALSE");

	HANDLE h = CreateFileW(w, 0, FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE, NULL, OPEN_EXISTING,
	                       FILE_FLAG_BACKUP_SEMANTICS, NULL);
	if (h == INVALID_HANDLE_VALUE) {
		Rprintf("    CreateFileW(0, OPEN_EXISTING, BACKUP_SEMANTICS), following links: error %s\n",
		        error_name(GetLastError()));
	} else {
		Rprintf("    CreateFileW(0, OPEN_EXISTING, BACKUP_SEMANTICS), following links: opened\n");
		print_final_path(h);
		CloseHandle(h);
	}
}

/* What the link stores, as fsutil reparsepoint query would show it. */
void probe_reparse(char **path) {
	const wchar_t *w = widen(path[0]);
	HANDLE h = CreateFileW(w, 0, FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE, NULL, OPEN_EXISTING,
	                       FILE_FLAG_OPEN_REPARSE_POINT | FILE_FLAG_BACKUP_SEMANTICS, NULL);
	if (h == INVALID_HANDLE_VALUE) {
		Rprintf("    reparse point: cannot open the link itself (error %s)\n", error_name(GetLastError()));
		return;
	}
	DWORD bytes = 0;
	if (!DeviceIoControl(h, FSCTL_GET_REPARSE_POINT, NULL, 0, reparse_buffer, sizeof reparse_buffer, &bytes, NULL)) {
		Rprintf("    reparse point: FSCTL_GET_REPARSE_POINT failed (error %s)\n", error_name(GetLastError()));
		CloseHandle(h);
		return;
	}
	CloseHandle(h);
	probe_symlink_reparse *r = (probe_symlink_reparse *)reparse_buffer;
	Rprintf("    reparse tag: 0x%08lx%s\n", (unsigned long)r->ReparseTag,
	        r->ReparseTag == IO_REPARSE_TAG_SYMLINK       ? " (IO_REPARSE_TAG_SYMLINK)"
	        : r->ReparseTag == IO_REPARSE_TAG_MOUNT_POINT ? " (IO_REPARSE_TAG_MOUNT_POINT)"
	                                                      : "");
	if (r->ReparseTag != IO_REPARSE_TAG_SYMLINK) {
		return;
	}
	Rprintf("    flags: 0x%lx (%s)\n", (unsigned long)r->Flags, (r->Flags & 1) ? "relative" : "absolute");
	Rprintf("    substitute name: %s\n", narrow(r->PathBuffer + r->SubstituteNameOffset / sizeof(WCHAR),
	                                            r->SubstituteNameLength / sizeof(WCHAR)));
	Rprintf("    print name: %s\n",
	        narrow(r->PathBuffer + r->PrintNameOffset / sizeof(WCHAR), r->PrintNameLength / sizeof(WCHAR)));
}

/*
 * One CreateFileW() through the path. Style 0 is the engine's read-write open
 * of a database file (LocalFileSystem::OpenFile() with a write lock), style 1
 * is what _wfopen(path, L"w") passes, which R's file.create() goes through.
 */
void probe_open(char **path, int *disposition, int *style) {
	const wchar_t *w = widen(path[0]);
	DWORD disp = (DWORD)*disposition;
	DWORD access = *style == 0 ? (GENERIC_READ | GENERIC_WRITE) : GENERIC_WRITE;
	DWORD share = *style == 0 ? FILE_SHARE_DELETE : (FILE_SHARE_READ | FILE_SHARE_WRITE);
	SetLastError(0);
	HANDLE h = CreateFileW(w, access, share, NULL, disp, FILE_ATTRIBUTE_NORMAL, NULL);
	DWORD e = GetLastError();
	const char *label = *style == 0 ? "engine's access and sharing" : "_wfopen's access and sharing";
	if (h == INVALID_HANDLE_VALUE) {
		Rprintf("    CreateFileW(%s, %s): error %s\n", disposition_name(disp), label, error_name(e));
	} else {
		Rprintf("    CreateFileW(%s, %s): opened, last error %s\n", disposition_name(disp), label, error_name(e));
		print_final_path(h);
		CloseHandle(h);
	}
}
