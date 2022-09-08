#include <stdio.h>

int main(void)
{
	int i;
	double A[5] = {
		9.0,
		2.9,
		3.E+25,
		.00007
		// the third difference would be the ordering of
		// elements in the array. In this version last
		// element is zero. But in the original code
		// it is the third element (by designation)
	};

	for (i = 0; i < 5; i++) {
		printf("element %d is %g, \tits square is %g\n",
		       i,
		       A[i],
		       A[i] * A[i]);
	}

	return 0;
}
