#!/bin/bash

find -L .data1/* -name ".*" -prune -o \
	-name "*.jugdata" -prune -o \
	\( -type f -exec stat -L --printf="%s\t%n\n" "{}" \; \)
