#pragma once

#if defined(_WIN32)

#ifndef NOMINMAX
#define NOMINMAX
#endif

#ifndef _WINSOCKAPI_
#define _WINSOCKAPI_
#endif

#include <windows.h>

#undef CreateDirectory
#undef MoveFile
#undef RemoveDirectory

// wingdi.h defines ERROR as 0, and the unity build is what turns that into a
// compile error: scripts/rconfigure.py concatenates a whole source directory
// into one translation unit, so one file reaching for <windows.h> poisons
// every `ERROR` enumerator that follows it in the same unit -- in a header
// that never asked for Windows and, upstream, never meets it, because upstream
// compiles one file at a time.
//
// Upstream's own answer to this class of collision is windows_undefs.hpp,
// included by each header that defines a hostile name. That cannot be the fix
// here: the header needing it is whichever one upstream adds next, so the
// patch would have to follow the engine rather than sit in one file. Undoing
// the macro where <windows.h> enters is the seam that does not move.
//
// Not the include either: windows_undefs.hpp is guarded on WIN32, which is not
// what guards this file, and a fix that silently does nothing on a toolchain
// that only sets _WIN32 is worse than a narrow one. Nothing here wants the GDI
// constant.
#undef ERROR

#endif
