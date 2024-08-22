#!/bin/bash 

set -xe
gcc -c lib/c_ffi.c -o lib/c_ffi.o 
ar rc ./lib/c_ffi.a lib/c_ffi.o
