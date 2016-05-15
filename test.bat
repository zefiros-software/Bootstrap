@echo off
for /r "bin" %%a in (*.exe) do (
    echo "%%~fa" test --file=test/tests.lua --systemscript=- --scripts=../
    "%%~fa" test --file=test/tests.lua --systemscript=- --scripts=../
)