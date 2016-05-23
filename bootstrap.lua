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
bootstrap._VERSION = "1.0.0-beta"
bootstrap.minReqVersion = ">5.0.0-alpha5"
bootstrap._LOADED = {}

    
bootstrap.globalDirectory = path.join( _PREMAKE_DIR, "modules" )
bootstrap.directories = { path.join( _MAIN_SCRIPT_DIR, "modules" ), bootstrap.globalDirectory }

-- Where do we currently look for modules
bootstrap._dirModules = nil

-- Quit on wrong premake verions
require("premake", bootstrap.minReqVersion)

-- Libs
bootstrap.semver = dofile( "semver.lua" )

--[[
-- The module loader, this should not be executed when running tests.
-- 
-- @post
-- * os.isdir( bootstrap._dirModules ) == true
-- ]]
function bootstrap.onLoad()
    
    if _ACTION ~= "test" then
        print( string.format( "Loading The Zefiros Bootstrap version '%s'...", bootstrap._VERSION ) )     
    end

    bootstrap.init( bootstrap.globalDirectory )
    
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

        if _ACTION ~= "test" then
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
    local matches = os.matchdirs( path.join( bootstrap._dirModules, string.format( "%s/%s/*", vendor, mod )  ) )
    
    for _, match in ipairs( matches ) do
        
        local loader = match:gsub( "([%w-_]+)/([%w-_]+)/(%d+%.%d+%.%d+.*)", "%1/%2/%3/%2" )
                
        if not os.isfile( loader .. ".lua" ) then
            loader= match:gsub( "([%w-_]+)/([%w-_]+)/(%d+%.%d+%.%d+.*)", "%1/%2/%3/init" )
        end
       
        if os.isfile( loader .. ".lua" ) then
        
            table.insert( result, { 
                version = match:match( ".*(%d+%.%d+%.%d+.*)" ),
                path = path.getdirectory( loader ),
                loader = loader
            } )
        end
        
    end
    
    table.sort( result, function( t1, t2 ) 
        
        local p1 = t1.path:match( "(.*)/%d+%.%d+%.%d+.*" )
        local p2 = t2.path:match( "(.*)/%d+%.%d+%.%d+.*" )
        if p1 ~= p2 then
            return p1 < p2
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
    local matches = os.matchdirs( path.join( bootstrap._dirModules, string.format( "%s/%s/head", vendor, mod ) ) )

    for _, match in ipairs( matches ) do
    
        local loader = match:gsub( "([%w-_]+)/([%w-_]+)/head", "%1/%2/head/%2" )
        
        if not os.isfile( loader .. ".lua" ) then
            loader = match:gsub( "([%w-_]+)/([%w-_]+)/head", "%1/%2/head/init" )
        end
                
        if os.isfile( loader .. ".lua" ) then
            table.insert( result, loader )
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
    
        -- restore in case
        package.path = oldPath
    
        error( mod )
        
    end
    
    package.path = oldPath
    
    return mod
    
end


-- [[
-- Requires the head of an installed module. 
-- This looks in the <vendor>/<module>/head/ folder
--
-- @param base     The base function we are overriding.
-- @param modName  The module name we are including. 
--
-- @returns
-- The loaded module object.
-- ]]
function bootstrap.requireVersionHead( base, modName )

    local oldPath = package.path
    local mod = {}
    
    -- very lame workaround
    local modPath = string.format( "/%s/%s/head/", modName[1], modName[2] )

    package.path = os.getcwd() .. "/?.lua;" ..
                   path.join( os.getcwd(), bootstrap._dirModules ) .. modPath .. "?.lua;" ..
                   package.path
                    
    local heads = bootstrap.listModulesHead( modName[1], modName[2] )
    local found = #heads > 0
    if found then
    
        local result, modf = pcall( base, heads[1] )
        
        if not result then
        
            -- restore in case
            package.path = oldPath
            
            error( modf )
            
        else
            mod = modf
        end
        
    else
    
        package.path = oldPath
        error( string.format( "Module with vendor '%s' and name '%s' not found,\nplease run 'premake5 install-module='%s/%s'!", modName[1], modName[2], modName[1], modName[2] ) )
        
    end
    
    package.path = oldPath
    
    return mod, found
end

-- [[
-- Requires the version of an installed module.
-- This looks in the <vendor>/<module>/<version>/ folders first,
-- when no releases are found this looks in the <vendor>/<module>/head/ folder
--
-- @param base         The base function we are overriding.
-- @param modName      The module name we are including. 
-- @param versionsStr  The version string the release should satisfy. 
--
-- @returns
-- The loaded module object.
-- ]]
function bootstrap.requireVersionsNew( base, modName, versionsStr )

    local oldPath = package.path
                
    local tags = bootstrap.listModulesTags( modName[1], modName[2] )   
    local mod = nil
        
    if #tags > 0 then
    
        local loaded = false
        for _, tag in pairs( tags ) do
        
            if mod == nil and ( versionsStr == nil or premake.checkVersion( tag.version, versionsStr ) ) then
            
                local modPath = string.format( "/%s/%s/%s/", modName[1], modName[2], tag.version )
                
                -- very lame workaround
                package.path = os.getcwd() .. "/?.lua;" ..
                               path.join( os.getcwd(), bootstrap._dirModules ) .. modPath .. "?.lua;" ..
                               package.path        
             
                local result, modf = pcall( base, tag.loader )
                
                if not result then
                
                    -- restore in case
                    package.path = oldPath
                    
                    error( modf )
                    
                else
                    mod = modf
                end
                
                loaded = true
            end            
            
            if not loaded then
                package.path = oldPath
                error( string.format( "Module with vendor '%s' and name '%s' has no releases satisfying version '%s'!", modName[1], modName[2], versionsStr ) )
            end
            
        end
    else
        
        if _ACTION ~= "test" then
            print( string.format( "Module with vendor '%s' and name '%s' has no releases, switching to head!", modName[1], modName[2] ) )
        end
        
        local ok, modf, found = pcall( bootstrap.requireVersionHead, base, modName )

        if not ok and found then
            
            package.path = oldPath
            error( string.format( "Module with vendor '%s' and name '%s' failed to load!\n%s", modName[1], modName[2], modf ) )
        
        elseif not ok and not found then
        
            package.path = oldPath
            error( modf )
 
        else
        
            mod = modf
        end
    end 
    
    package.path = oldPath
    
    return mod
end

function bootstrap.requireVersions( base, modName, versions )

    if versions == "@head" then
        local modSplit = bootstrap.getModule( modName )
        return bootstrap.requireVersionHead( base, modSplit )   
    end
    
    local mod = nil
    local result, modf = pcall( bootstrap.requireVersionsOld, base, modName, versions )  

    if not result then
        
        local modSplit = bootstrap.getModule( modName )
        local resultn, modfn = pcall( bootstrap.requireVersionsNew, base, modSplit, versions )  

        if not resultn then
            
            error( modfn )
            
        else
            mod = modfn
        end
        
    else
        mod = modf
    end
    
    return mod
end

function bootstrap.requireVersionsFromDirectories( base, modName, versions )
   
    local err = ""

    for _, dir in pairs( bootstrap.directories ) do
    
        bootstrap._dirModules = dir
        
        local ok, modfn = pcall( bootstrap.requireVersions, base, modName, versions )  
        
        if ok then
            
            -- reset current path
            bootstrap._dirModules = nil
            
            return modfn
            
        else
            err = modfn
        end
    end
    
    -- reset current path
    bootstrap._dirModules = nil
    
    error( err )
end

function bootstrap.require(  base, modName, versions )
    
    if bootstrap._LOADED[ modName ] ~= nil then
        return bootstrap._LOADED[ modName ]
    end

    local mod = bootstrap.requireVersionsFromDirectories( base, modName, versions )
    
    bootstrap._LOADED[ modName ] = mod
    
    if type(mod) == "table" and mod.onLoad ~= nil then
    
        if mod.__isLoaded == nil then
            mod.onLoad()
        end
        
        mod.__isLoaded = true
    end    
        
    return mod

end

if _ACTION ~= "test" then

    premake.override( _G, "require", bootstrap.require )

    premake.override( premake, "checkVersion", bootstrap.checkVersion )

    bootstrap.onLoad()
    
end

return bootstrap