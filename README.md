# Bootstrap Module
This premake5 module ensures you can easily load modules for [ZPM](http://zpm.zefiros.eu/).

# Status
OS          | Status
----------- | -------
Linux & OSX | [![Build Status](https://travis-ci.org/Zefiros-Software/Bootstrap.svg?branch=master)](https://travis-ci.org/Zefiros-Software/Bootstrap)
Windows     |

# Usage
Use the following function as the new default `premake5` require:
```lua
bootstrap.require( base, modName, versionString )
```