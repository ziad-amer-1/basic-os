#!/bin/bash

build_location=build/

if [ -f "$build_location"]; then
  make clean
fi

make && qemu-system-i386 -fda build/main_floppy.img