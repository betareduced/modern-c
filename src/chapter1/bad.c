/* Fix 1: Add headers */
#include <stdio.h>

/* Fix 2: Set return type for main */
int main(void)
{
	int i;
	double A[5] = {
		9.0,
		2.9,
		/* Fix 3: Order of elements (without designated elements) */
		0,
		.0007,
		3.E+25
	};

	for (i = 0; i < 5; ++i) {
		printf("element %d is %g, \tits square is %g\n",
		       i,
		       A[i],
		       A[i] * A[i]);
	}

	return 0;
}
