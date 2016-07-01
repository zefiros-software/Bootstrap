# Bootstrap Module
This premake5 module ensures you can easily load modules for [ZPM](http://zpm.zefiros.eu/).

# Usage
Use the following function as the new default `premake5` require:
```lua
bootstrap.require( base, modName, versionString )
```