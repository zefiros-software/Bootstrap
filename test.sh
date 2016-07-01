#!/bin/bash

for filename in /bin/premake*; do    
    echo $filename "test --file=test/tests.lua --systemscript=- --scripts=../"
    $filename "test --file=test/tests.lua --systemscript=- --scripts=../"
done