#!/bin/bash

for filename in bin/premake*; do    
    file = $(cd "./$filename"; pwd)
    echo "$file test --file=test/tests.lua --systemscript=- --scripts=../"
    "$file test --file=test/tests.lua --systemscript=- --scripts=../"
done