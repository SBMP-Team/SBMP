#!/bin/fish
$dir = $(pwd)

cd ~/Projects/C/SBMP
make compiler
./build/sbmpc ./tests/test.sbmp

cd $dir