#!/bin/bash

for filename in bin/premake*; do    
    file = "./$filename"
    echo "$file test --file=test/tests.lua --systemscript=- --scripts=../"
    "$file test --file=test/tests.lua --systemscript=- --scripts=../"
done