/* Two C calls that block the R main thread the way a network wait inside
   the engine does, differing only in whether they ask R about interrupts.

   Build with `R CMD SHLIB blocking_poll.c`; run.sh does that. */

#include <R.h>
#include <Rinternals.h>
#include <poll.h>

/* Never asks: the shape of a wait the engine cannot come back from. */
SEXP block_unchecked(SEXP secs) {
	int n = INTEGER(secs)[0];
	for (int i = 0; i < n; i++) {
		poll(NULL, 0, 1000);
	}
	return ScalarInteger(n);
}

/* Asks once a second: the shape R's own interrupt is built for. */
SEXP block_checked(SEXP secs) {
	int n = INTEGER(secs)[0];
	for (int i = 0; i < n; i++) {
		poll(NULL, 0, 1000);
		R_CheckUserInterrupt();
	}
	return ScalarInteger(n);
}
