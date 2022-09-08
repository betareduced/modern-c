CC=gcc
CFLAGS=-Wall -Werror -std=c11

all: getting_started getting_started_fix

getting_started: getting_started.c
getting_started_fix: getting_started_fix.c

.PHONY: clean
clean:
	@rm -fv getting_started getting_started_fix
