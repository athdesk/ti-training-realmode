#!/bin/bash

socat TCP-LISTEN:1337,fork,reuseaddr EXEC:"timeout 120 qemu-system-i386 -display none -serial stdio -drive file=/tmp/boot.bin\,format=raw -snapshot",pty,stderr
