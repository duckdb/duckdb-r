/* Report which SIGINT handler is installed, from inside the process.
 *
 * A debugger cannot answer this comfortably on macOS, and the layout of
 * struct sigaction differs per platform anyway, so ask the C library
 * instead: sigaction(2) reads the disposition and dladdr(3) names the
 * library and symbol owning it. A sampling thread does it while the main
 * thread is blocked in the wait under investigation, which is the moment
 * that matters and the moment nothing else can look.
 *
 * Deliberately free of the R API -- no R headers, no R symbols, and an
 * interface `.C()` can reach. That is what lets one build serve both
 * hosts: dyn.load() it into R, or preload it into the DuckDB CLI
 * (LD_PRELOAD on Linux, DYLD_INSERT_LIBRARIES on macOS) with
 * DUCKDB_SIGPROBE set, and the constructor starts the same sampler.
 *
 * The sampling thread touches nothing but sigaction, dladdr and write,
 * so it stays clear of both R's single-threaded API and the engine.
 */

/* glibc hides dladdr() and Dl_info behind this; macOS declares them always. */
#ifndef _GNU_SOURCE
#define _GNU_SOURCE
#endif

#include <dlfcn.h>
#include <pthread.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>

static void describe(char *buf, size_t n) {
	struct sigaction sa;
	memset(&sa, 0, sizeof(sa));
	if (sigaction(SIGINT, NULL, &sa) != 0) {
		snprintf(buf, n, "sigaction() failed");
		return;
	}

	/* sa_handler and sa_sigaction share storage; either reads the pointer. */
	void *handler = (void *)(size_t)sa.sa_handler;
	const char *lib = "-";
	const char *sym = "-";
	Dl_info info;

	if (handler == (void *)(size_t)SIG_DFL) {
		lib = "SIG_DFL";
	} else if (handler == (void *)(size_t)SIG_IGN) {
		lib = "SIG_IGN";
	} else if (dladdr(handler, &info)) {
		if (info.dli_fname) {
			lib = info.dli_fname;
		}
		if (info.dli_sname) {
			sym = info.dli_sname;
		}
	}

	snprintf(buf, n, "handler=%p SA_RESTART=%d flags=0x%x sym=%s lib=%s", handler,
	         (sa.sa_flags & SA_RESTART) != 0, (unsigned)sa.sa_flags, sym, lib);
}

static void emit(const char *tag) {
	char what[1024];
	char line[1200];
	describe(what, sizeof(what));
	/* The pid matters under a preload, which every child inherits: a shell
	   wrapper or a `timeout` in front of the host reports itself too. */
	snprintf(line, sizeof(line), "[sigprobe pid=%ld %s] %s\n", (long)getpid(), tag, what);
	/* write(2) rather than stderr buffering: this races a blocked host. */
	if (write(2, line, strlen(line)) < 0) {
		/* nothing useful to do about it */
	}
}

struct sampler {
	double interval;
	int count;
};

static void *sample(void *arg) {
	struct sampler *s = (struct sampler *)arg;
	char tag[32];
	struct timespec ts;
	ts.tv_sec = (time_t)s->interval;
	ts.tv_nsec = (long)((s->interval - (double)ts.tv_sec) * 1e9);

	for (int i = 0; i < s->count; i++) {
		nanosleep(&ts, NULL);
		snprintf(tag, sizeof(tag), "t+%.0fs", s->interval * (double)(i + 1));
		emit(tag);
	}
	free(s);
	return NULL;
}

/* .C("sigprobe_now") -- one reading, right now. */
void sigprobe_now(void) {
	emit("now");
}

/* .C("sigprobe_start", as.double(interval), as.integer(count)) */
void sigprobe_start(double *interval, int *count) {
	struct sampler *s = (struct sampler *)malloc(sizeof(struct sampler));
	if (!s) {
		return;
	}
	s->interval = *interval > 0 ? *interval : 1.0;
	s->count = *count > 0 ? *count : 60;

	pthread_t tid;
	if (pthread_create(&tid, NULL, sample, s) != 0) {
		free(s);
		return;
	}
	pthread_detach(tid);
}

/* Preload entry: DUCKDB_SIGPROBE="<interval seconds>:<count>". */
__attribute__((constructor)) static void sigprobe_autostart(void) {
	const char *spec = getenv("DUCKDB_SIGPROBE");
	if (!spec) {
		return;
	}
	double interval = atof(spec);
	const char *colon = strchr(spec, ':');
	int count = colon ? atoi(colon + 1) : 60;
	sigprobe_start(&interval, &count);
}
