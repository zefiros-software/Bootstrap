--[[ @cond ___LICENSE___
-- Copyright (c) 2016 Koen Visscher, Paul Visscher and individual contributors.
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
-- THE SOFTWARE.
--
-- @endcond
--]]


-- Bootstrap
bootstrap = {}
bootstrap._VERSION = "1.0.0-alpha"
bootstrap._LOADED = {}

-- Default the modules directory locally
bootstrap.dirModules = path.join( _MAIN_SCRIPT_DIR, "modules" )

-- Libs
bootstrap.semver = dofile( "semver.lua" )

-- The modules folder is not there switch to installed folder
-- This functionality cannot be unit tested
if not os.isdir( bootstrap.dirModules ) then

    bootstrap.dirModules = path.join( _PREMAKE_DIR, "modules" )
    
end

--[[
-- The module loader, this should not be executed when running tests.
-- 
-- @post
-- * os.isdir( bootstrap.dirModules ) == true
-- ]]
function bootstrap.onLoad()
    
    if not _ACTION == "test" then
        print( "Loading zpm bootstrap..." )       
    end

    bootstrap.init( bootstrap.dirModules )
    
end

-- [[
-- Initialises the bootstrap loader by creating the correct directories
-- needed to function correctly
-- 
-- @post
-- * os.isdir( directory ) == true
-- ]]
function bootstrap.init( directory )
    
    if not os.isdir( directory ) then    

        if not _ACTION == "test" then
            print( "Creating modules directory..." )            
        end
    
        assert( os.mkdir( directory ) )        
    end

end

-- [[
-- Seperates the vendor and module name from the module string.
--
-- @pre 
-- * modName is in the form "<vendor>/<module>" where both <vendor> and <module> are alphanumeric, - or _
-- * modName is in the form "<module>" where <module> is alphanumeric, - or _
--
-- @returns 
-- An array with vendor name first and then module name
-- ]]
function bootstrap.getModule( modName )

    assert( modName:len() > 0, "Given module may not be empty ''!" )

    local mod = modName:explode( "/" )
    assert( mod[1] == mod[1]:gsub( "[^[%w-_]]*", "" ), string.format( "Vendor name '%s' must be alphanumeric!", mod[1]:gsub( "[^[%w-]]", "" ) ) )
    assert( mod[1]:len() > 0, "Vendor name may not be empty!" )
    
    if #mod > 1 then
        assert( mod[2] == mod[2]:gsub( "[^[%w-_]]*", "" ), string.format( "Module name '%s' must be alphanumeric!", mod[2] ) )
        assert( mod[2]:len() > 0, "Module name may not be empty!" )
    end

    return mod
    
end

-- [[
-- Retrieves all module tag folders with the given vendor or module name.
--
-- @param vendor    [optional] The vendor name to match, defaults to "*"
-- @param venmoddor [optional] The module name to match, defaults to "*"
--
-- @returns
-- A version sorted (newest first) table of tags that match the given filters
--
-- @pre
-- * Searches <modules dir>/<vendor>/<module>/<version>/, 
--   where either <module>.lua or init.lua exists.
-- ]]
function bootstrap.listModulesTags( vendor --[[ = "*" ]], mod --[[ = "*" ]] )

    vendor = vendor or "*"
    mod = mod or "*"

    local result = {}
    local matches = os.matchdirs( path.join( bootstrap.dirModules, string.format( "%s/%s/*", vendor, mod )  ) )
    
    for _, match in ipairs( matches ) do
    
        local loader = match:gsub( "([%w-]+)/([%w-]+)/(%d+%.%d+%.%d+.*)", "%1/%2/%3/%2.lua" )
        
        if not os.isfile( loader ) then
            loader= match:gsub( "([%w-]+)/([%w-]+)/(%d+%.%d+%.%d+.*)", "%1/%2/%3/init.lua" )
        end
       
        if os.isfile( loader ) then
            
            table.insert( result, { 
                version = match:match( ".*(%d+%.%d+%.%d+.*)" ),
                path = path.getdirectory( loader )
            } )
        end
        
    end
    
    table.sort( result, function( t1, t2 ) 
        
        local p1 = t1.path:match( "(.*)/%d+%.%d+%.%d+.*" )
        local p2 = t2.path:match( "(.*)/%d+%.%d+%.%d+.*" )
        if p1 ~= p2 then
            return p1 > p2
        end
        
        return bootstrap.semver( t1.version ) > bootstrap.semver( t2.version )
    end )
    
    return result
end

-- [[
-- Retrieves all module head folders with the given vendor or module name.
--
-- @param vendor    [optional] The vendor name to match, defaults to "*"
-- @param venmoddor [optional] The module name to match, defaults to "*"
--
-- @returns
-- A version sorted (newest first) table of heads that match the given filters
--
-- @pre
-- * Searches <modules dir>/<vendor>/<module>/head/, 
--   where either <module>.lua or init.lua exists.
-- ]]
function bootstrap.listModulesHead( vendor, mod )

    vendor = vendor or "*"
    mod = mod or "*"

    local result = {}
    local matches = os.matchdirs( path.join( bootstrap.dirModules, string.format( "%s/%s/head", vendor, mod ) ) )
    
    for _, match in ipairs( matches ) do
    
        local loader = match:gsub( "([%w-]+)/([%w-]+)/head", "%1/%2/head/%2.lua" )
        
        if not os.isfile( loader ) then
            loader = match:gsub( "([%w-]+)/([%w-]+)/head", "%1/%2/head/init.lua" )
        end
                
        if os.isfile( loader ) then
            table.insert( result, path.getdirectory( loader ) )
        end
        
    end
    
    return result
end
    
-- [[
-- The bootstrap version of checking version strings. The || operator takes 
-- precedance over other operators.
--
-- @param base     The base function to check versions with.
-- @param version  The version string to check with.
-- @param versions The versions string to check against.
--
-- @returns
-- 
-- ]]
function bootstrap.checkVersion( base, version, versions )

    for _, v in ipairs( string.explode( versions, "||" ) ) do
    
        -- trim version sstring
        if base( version, v:gsub("^%s*(.-)%s*$", "%1") ) then
            return true
        end
    
    end

    return false
    
end

-- [[
-- Requires the old way before overriding given the given parameters.
-- This function will rethrow any errors given.
--
-- @param base     The base function we are overriding.
-- @param modName  The module name we are including. 
-- @param versions The version of the module we are including.
--
-- @returns
-- The loaded module object.
-- ]]
function bootstrap.requireVersionsOld( base, modName, versions )

    local oldPath = package.path
    -- very lame workaround
    package.path = os.getcwd() .. "/" .. modName .. "/../?.lua;" .. package.path
    
    local result, mod = pcall( base, modName )
    
    if not result then
    
        error( mod )
        
    end
    
    package.path = oldPath
    
    return mod
    
end

function bootstrap.requireVersionHead( base, modName )

    local oldPath = package.path
    local mod = {}
    
    -- very lame workaround
    local modPath = string.format( "%s/%s/head/%s.lua", modName[1], modName[2], modName[2] )
    package.path =  modPath .. ";" .. 
                    os.getcwd() .. "/" .. modPath .. ";" .. 
                    bootstrap.dirModules .. "/" .. modPath .. ";" .. 
                    package.path

    local heads = bootstrap.listModulesHead( modName[1], modName[2] )
    
    if #heads > 0 then
        
        mod = base( heads[1] )
        
    else
        error( string.format( "Module with vendor '%s' and name '%s' not found!", modName[1], modName[2] ) )
    end
    
    package.path = oldPath
    
    return mod
end

function bootstrap.requireVersionsNew( base, modName, versions )

    local oldPath = package.path
                
    local tags = bootstrap.listModulesTags( modName[1], modName[2] )   
    local mod = {}
    
    if #tags > 0 then
    
        for _, tag in pairs( tags ) do
        
            if versions == nil or premake.checkVersion( tag.version, versions ) then
            
                -- very lame workaround
                package.path = tag.path .. ";" .. package.path
                
                mod =  base( tag.path )
                
            end
        end
    else
    
        local mods = bootstrap.requireVersionHead( base, modSplit )
        
        if #mods > 0 then
            
            package.path = mods[1] .. ";" .. package.path
            mod = base( mods[1], versions )
        
        else
    
            if versions ~= nil then
                
                package.path = oldPath
                error( string.format( "No module from vendor '%s' with the name '%s' found satisfies versions '%s'!\nAvailable are versions:\n", modName[1], modName[2], versions ) .. table.tostring( tags, true ) )
            else        
            
                package.path = oldPath
                error( string.format( "No module from vendor '%s' with the name '%s' found!", modName[1], modName[2] ) )
            end
            
            package.path = oldPath
            error( string.format( "Run 'premake5 install-module='%s/%s'", modName[1], modName[2] ) )
        end
    end 
    
    package.path = oldPath
    
    return mod
end

function bootstrap.requireVersions( base, modName, versions )
        
    local modSplit = bootstrap.getModule( modName )
    if #modSplit > 1 and not ( os.isdir( modName ) or os.isfile( modName ) or os.isfile( modName .. ".lua" ) ) then

        if versions == "@head" then
        
            return bootstrap.requireVersionHead( base, modSplit )        
        
        else
        
            return bootstrap.requireVersionsNew( base, modSplit, versions )  
            
        end
    
    else    
    
        return bootstrap.requireVersionsOld( base, modName, versions )      
          
    end
end

function bootstrap.require(  base, modName, versions )
    
    if bootstrap._LOADED[ modName ] ~= nil then
        return bootstrap._LOADED[ modName ]
    end

    local mod = bootstrap.requireVersions( base, modName, versions )
    
    bootstrap._LOADED[ modName ] = mod
    
    if type(mod) == "table" and mod.onLoad ~= nil then
    
        if mod.isLoaded == nil then
            mod.onLoad()
        end
        
        mod.isLoaded = false
    end    
        
    return mod

end

if not _ACTION == "test" then

    premake.override( _G, "require", bootstrap.require )

    premake.override( premake, "checkVersion", bootstrap.checkVersion )

    bootstrap.onLoad()
    
end

return bootstrap