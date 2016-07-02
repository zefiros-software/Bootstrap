# Bootstrap Module
[![Build Status](https://travis-ci.org/Zefiros-Software/Bootstrap.svg?branch=master)](https://travis-ci.org/Zefiros-Software/Bootstrap)

This premake5 module ensures you can easily load modules for [ZPM](http://zpm.zefiros.eu/).

# Usage
Use the following function as the new default `premake5` require:
```lua
bootstrap.require( base, modName, versionString )
```