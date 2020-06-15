#!/bin/bash

find -L * -name ".*" -prune -o \
	-name "*.jugdata" -prune -o \
	\( -type f -exec stat -L --printf="%s\t%n\n" "{}" \; \)
