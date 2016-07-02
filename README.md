# Bootstrap Module
This premake5 module ensures you can easily load modules for [ZPM](http://zpm.zefiros.eu/).

# Status
OS          | Status
----------- | -------
Linux & OSX | [![Build Status](https://travis-ci.org/Zefiros-Software/Bootstrap.svg?branch=master)](https://travis-ci.org/Zefiros-Software/Bootstrap)
Windows     | [![Build status](https://ci.appveyor.com/api/projects/status/1vx5h52ja1tthfs1?svg=true)](https://ci.appveyor.com/project/PaulVisscher/bootstrap)

# Usage
Use the following function as the new default `premake5` require:
```lua
bootstrap.require( base, modName, versionString )
```