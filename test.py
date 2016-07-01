import os, glob

for file in glob.glob( "bin/premake*" ):
    command = "%s test --file=test/tests.lua --systemscript=- --scripts=./" % file
    print( command )
    os.system( command )