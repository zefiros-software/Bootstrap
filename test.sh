#!/bin/bash

for filename in bin/premake*; do    
    echo (readlink -f "./"$filename) " test --file=test/tests.lua --systemscript=- --scripts=../"
    (readlink -f "./"$filename) " test --file=test/tests.lua --systemscript=- --scripts=../"
done