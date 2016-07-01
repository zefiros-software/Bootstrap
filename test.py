import os, glob

for file in glob.glob( "bin/premake*" ):
    command = "%s test --file=test/tests.lua --systemscript=- --scripts=./" % file
    print( command )
    code = os.system( command )
    if code != 0:
        exit(-1)