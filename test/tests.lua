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

-- Libraries
local u = require "extern.luaunit"

require( "bootstrap" )

-- Mocking

-- Load environment
dofile( "action/test.lua" )

TestBootstrap = {} 
    function TestBootstrap:testBootstrapExists()
        u.assertNotEquals( bootstrap, nil )
        u.assertIsTable( bootstrap )
    end
	
    function TestBootstrap:testSemverExists()
        u.assertNotEquals( bootstrap.semver, nil )
    end
	
	function TestBootstrap:testSemver()
	 	u.assertEquals( bootstrap.semver( '2.5.1' ), bootstrap.semver( 2, 5, 1 ) )
	end
	
    function TestBootstrap:testCorrectVersion()
        bootstrap.semver( bootstrap._VERSION )
        u.assertIsString( bootstrap._VERSION )
    end
	
    function TestBootstrap:testDirModules()
        u.assertIsNil( bootstrap._dirModules )
    end
	
    function TestBootstrap:testDirectories()
        u.assertIsTable( bootstrap.directories )
		
		for _, dir in pairs( bootstrap.directories ) do
			u.assertIsString( dir )		
		end
		
    end
	
    function TestBootstrap:testOnLoad_CorrectInit()
	
		local i = bootstrap.init
		
		local dir = ""
		
		bootstrap.init = function( directory )
			dir = directory
		end
		
		bootstrap.onLoad()
		
	 	u.assertEquals( dir, bootstrap.globalDirectory )
		
		bootstrap.init = i
		
    end
	
    function TestBootstrap:testInit()
	
		u.assertFalse( os.isdir( "modules-test" ) ) 
		
        bootstrap.init( "modules-test" )
		
		u.assertTrue( os.isdir( "modules-test" ) ) 
		
		os.rmdir( "modules-test" )
		
		u.assertFalse( os.isdir( "modules-test" ) ) 
    end
	
    function TestBootstrap:testInit_CantMake()
	
		u.assertFalse( os.isdir( "modules<>test" ) ) 
		
		bootstrap.init( "modules<>test" )

        u.assertErrorMsgContains( "unable to create directory", bootstrap.init, "modules<>test" )
				
		u.assertFalse( os.isdir( "modules<>test" ) ) 
    end
	
    function TestBootstrap:testGetModule()
	
		u.assertItemsEquals( bootstrap.getModule( "Zefiros-Software/zpm" ), { "Zefiros-Software", "zpm" } ) 
		u.assertItemsEquals( bootstrap.getModule( "Zefiros-Software/zpm-zpm" ), { "Zefiros-Software", "zpm-zpm" } ) 
		u.assertItemsEquals( bootstrap.getModule( "Zefiros-Software/zpm_zpm" ), { "Zefiros-Software", "zpm_zpm" } ) 
		u.assertItemsEquals( bootstrap.getModule( "Zefiros-Software" ), { "Zefiros-Software" } ) 
		u.assertItemsEquals( bootstrap.getModule( "Zefiros_Software" ), { "Zefiros_Software" } ) 
		u.assertItemsEquals( bootstrap.getModule( "zpm" ), { "zpm" } ) 

    end
	
    function TestBootstrap:testGetModule_Empty()
		u.assertErrorMsgContains( "Given module may not be empty ''!", bootstrap.getModule, "" )

    end
	
    function TestBootstrap:testGetModule_AlphanumericVendor()
		u.assertErrorMsgContains( "Vendor name 'Zefiros-Software$' must be alphanumeric!", bootstrap.getModule, "Zefiros-Software$/zpm" )
		u.assertErrorMsgContains( "Module name 'zpm%zpm' must be alphanumeric!", bootstrap.getModule, "Zefiros-Software/zpm%zpm" )
		u.assertErrorMsgContains( "Vendor name 'Zefiros-Software$' must be alphanumeric!", bootstrap.getModule, "Zefiros-Software$/zpm%zpm" )
		u.assertErrorMsgContains( "Vendor name may not be empty!", bootstrap.getModule, "/zpm" )
		u.assertErrorMsgContains( "Module name may not be empty!", bootstrap.getModule, "zpm/" )
				
    end
	
    function TestBootstrap:testListModulesTags_NoInit()

		-- init
		local dirMods = bootstrap._dirModules
		bootstrap._dirModules = "./modules-test"
		
		local dirs = { 
			"modules-test/Zefiros-Software/zpm/1.0.0-alpha", 
			"modules-test/Zefiros-Software/zpm/0.0.1", 
			"modules-test/Zefiros-Software/zpm/3.0.0",
			
			"modules-test/Zefiros-Software/zpm2/1.0.0-beta", 
			"modules-test/Zefiros-Software/zpm2/0.0.1", 
			"modules-test/Zefiros-Software/zpm2/2.0.0",
			
			"modules-test/Zefiros-Softwarefe/df/1.5.4-ga", 
			"modules-test/Zefiros-Softwarefe/df/0.3.1", 
			"modules-test/Zefiros-Softwarefe/df/3.4.0" 
		}
		
		for _, dir in ipairs( dirs ) do
			
			assert( os.mkdir( dir ) )
			u.assertTrue( os.isdir( dir ) )
		end
		
		-- test
		
		local tags = bootstrap.listModulesTags()
		u.assertEquals( #tags, 0 )
		os.rmdir( "modules-test" )
		
		u.assertFalse( os.isdir( "modules-test" ) ) 
		bootstrap._dirModules = dirMods
	
    end
	
    function TestBootstrap:testListModulesTags_Init()

		-- init
		local dirMods = bootstrap._dirModules
		bootstrap._dirModules = "./modules-test"
		
		local dirs = { 
			"modules-test/Zefiros-Software/zpm/1.0.0-alpha", 
			"modules-test/Zefiros-Software/zpm/0.0.1", 
			"modules-test/Zefiros-Software/zpm/3.0.0",
			
			"modules-test/Zefiros-Software/azpm2/1.0.0-beta", 
			"modules-test/Zefiros-Software/azpm2/0.0.1", 
			"modules-test/Zefiros-Software/azpm2/2.0.0",
			
			"modules-test/Zefiros-Softwarefe/df/1.5.4-ga", 
			"modules-test/Zefiros-Softwarefe/df/0.3.1", 
			"modules-test/Zefiros-Softwarefe/df/3.4.0"
		}
		
		for _, dir in ipairs( dirs ) do
			
			u.assertFalse( os.isdir( dir ) )
			assert( os.mkdir( dir ) )
			u.assertTrue( os.isdir( dir ) )
			
			local file = io.open( dir .. "/init.lua", "w" )
			file:close()
		end
		
		-- test
		
		local tags = bootstrap.listModulesTags()
		u.assertEquals( #tags, 9 )
		u.assertItemsEquals( tags, {			
			{
				loader = "modules-test/Zefiros-Softwarefe/df/3.4.0/init",
				path = "modules-test/Zefiros-Softwarefe/df/3.4.0",
				version = "3.4.0"
			},
			{
				loader = "modules-test/Zefiros-Softwarefe/df/1.5.4-ga/init",
				path = "modules-test/Zefiros-Softwarefe/df/1.5.4-ga", 
				version = "1.5.4-ga"
			},
			{
				loader = "modules-test/Zefiros-Softwarefe/df/0.3.1/init",
				path = "modules-test/Zefiros-Softwarefe/df/0.3.1", 
				version = "0.3.1"
			},
			{
				loader = "modules-test/Zefiros-Software/azpm2/2.0.0/init",
				path = "modules-test/Zefiros-Software/azpm2/2.0.0",
				version = "2.0.0"
			},
			{
				loader = "modules-test/Zefiros-Software/azpm2/1.0.0-beta/init",
				path = "modules-test/Zefiros-Software/azpm2/1.0.0-beta", 
				version = "1.0.0-beta"
			},
			{
				loader = "modules-test/Zefiros-Software/azpm2/0.0.1/init",
				path = "modules-test/Zefiros-Software/azpm2/0.0.1", 
				version = "0.0.1"
			},
			{
				loader = "modules-test/Zefiros-Software/zpm/3.0.0/init",
				path = "modules-test/Zefiros-Software/zpm/3.0.0",
				version = "3.0.0"
			},
			{
				loader = "modules-test/Zefiros-Software/zpm/1.0.0-alpha/init",
				path = "modules-test/Zefiros-Software/zpm/1.0.0-alpha",
				version = "1.0.0-alpha"
			},
			{
				loader = "modules-test/Zefiros-Software/zpm/0.0.1/init",
				path = "modules-test/Zefiros-Software/zpm/0.0.1",
				version = "0.0.1"
			}
		} ) 
		
		-- cleanup
		os.rmdir( "modules-test" )
		
		u.assertFalse( os.isdir( "modules-test" ) ) 
		bootstrap._dirModules = dirMods
	
    end
	
    function TestBootstrap:testListModulesTags_InitModule()

		-- init
		local dirMods = bootstrap._dirModules
		bootstrap._dirModules = "./modules-test"
		
		local dirs = { 
			"modules-test/Zefiros-Software/zpm/1.0.0-alpha", 
			"modules-test/Zefiros-Software/zpm/0.0.1", 
			"modules-test/Zefiros-Software/zpm/3.0.0",
			
			"modules-test/Zefiros-Software/zpm/1.0.0-beta", 
			"modules-test/Zefiros-Software/zpm/0.0.2", 
			"modules-test/Zefiros-Software/zpm/2.0.0",
			
			"modules-test/Zefiros-Softwarefe/zpm/1.5.4-ga", 
			"modules-test/Zefiros-Softwarefe/zpm/0.3.1", 
			"modules-test/Zefiros-Softwarefe/zpm/3.4.0"
		}
		
		for _, dir in ipairs( dirs ) do
			
			u.assertFalse( os.isdir( dir ) )
			assert( os.mkdir( dir ) )
			u.assertTrue( os.isdir( dir ) )
			
			local file = io.open( dir .. "/zpm.lua", "w" )
			file:close()
		end
		
		-- test
		local tags = bootstrap.listModulesTags()
		u.assertEquals( #tags, 9 )
		u.assertItemsEquals( tags, {			
			{
				loader = "modules-test/Zefiros-Softwarefe/zpm/3.4.0/zpm",
				path = "modules-test/Zefiros-Softwarefe/zpm/3.4.0",
				version = "3.4.0"
			},
			{
				loader = "modules-test/Zefiros-Softwarefe/zpm/1.5.4-ga/zpm",
				path = "modules-test/Zefiros-Softwarefe/zpm/1.5.4-ga", 
				version = "1.5.4-ga"
			},
			{
				loader = "modules-test/Zefiros-Softwarefe/zpm/0.3.1/zpm",
				path = "modules-test/Zefiros-Softwarefe/zpm/0.3.1", 
				version = "0.3.1"
			},
			{
				loader = "modules-test/Zefiros-Software/zpm/3.0.0/zpm",
				path = "modules-test/Zefiros-Software/zpm/3.0.0",
				version = "3.0.0"
			},
			{
				loader = "modules-test/Zefiros-Software/zpm/2.0.0/zpm",
				path = "modules-test/Zefiros-Software/zpm/2.0.0",
				version = "2.0.0"
			},
			{
				loader = "modules-test/Zefiros-Software/zpm/1.0.0-beta/zpm",
				path = "modules-test/Zefiros-Software/zpm/1.0.0-beta", 
				version = "1.0.0-beta"
			},
			{
				loader = "modules-test/Zefiros-Software/zpm/1.0.0-alpha/zpm",
				path = "modules-test/Zefiros-Software/zpm/1.0.0-alpha",
				version = "1.0.0-alpha"
			},
			{
				loader = "modules-test/Zefiros-Software/zpm/0.0.2/zpm",
				path = "modules-test/Zefiros-Software/zpm/0.0.2", 
				version = "0.0.2"
			},
			{
				loader = "modules-test/Zefiros-Software/zpm/0.0.1/zpm",
				path = "modules-test/Zefiros-Software/zpm/0.0.1",
				version = "0.0.1"
			}
		} ) 
		
		-- cleanup
		os.rmdir( "modules-test" )
		
		u.assertFalse( os.isdir( "modules-test" ) ) 
		bootstrap._dirModules = dirMods
	
    end
	
    function TestBootstrap:testListModulesTags_HeadIgnored()

		-- init
		local dirMods = bootstrap._dirModules
		bootstrap._dirModules = "./modules-test"
		
		local dirs = { 
			"modules-test/Zefiros-Software/zpm/head", 
			"modules-test/Zefiros-Software/zpm/1.0.0-alpha", 
			"modules-test/Zefiros-Software/zpm/0.0.1", 
			"modules-test/Zefiros-Software/zpm/3.0.0",
			
			"modules-test/Zefiros-Software/zpm2/1.0.0-beta", 
			"modules-test/Zefiros-Software/zpm2/0.0.1", 
			"modules-test/Zefiros-Software/zpm2/2.0.0",
			
			"modules-test/Zefiros-Softwarefe/df/1.5.4-ga", 
			"modules-test/Zefiros-Softwarefe/df/0.3.1", 
			"modules-test/Zefiros-Softwarefe/df/3.4.0"
		}
		
		for _, dir in ipairs( dirs ) do
						
			u.assertFalse( os.isdir( dir ) )
			assert( os.mkdir( dir ) )
			u.assertTrue( os.isdir( dir ) )
			
			local file = io.open( dir .. "/init.lua", "w" )
			file:close()
		end
		
		-- test
		
		local tags = bootstrap.listModulesTags()
		u.assertEquals( #tags, 9 )
		u.assertItemsEquals( tags, {			
			{
				loader = "modules-test/Zefiros-Softwarefe/df/3.4.0/init",
				path = "modules-test/Zefiros-Softwarefe/df/3.4.0",
				version = "3.4.0"
			},
			{
				loader = "modules-test/Zefiros-Softwarefe/df/1.5.4-ga/init",
				path = "modules-test/Zefiros-Softwarefe/df/1.5.4-ga", 
				version = "1.5.4-ga"
			},
			{
				loader = "modules-test/Zefiros-Softwarefe/df/0.3.1/init",
				path = "modules-test/Zefiros-Softwarefe/df/0.3.1", 
				version = "0.3.1"
			},
			{
				loader = "modules-test/Zefiros-Software/zpm2/2.0.0/init",
				path = "modules-test/Zefiros-Software/zpm2/2.0.0",
				version = "2.0.0"
			},
			{
				loader = "modules-test/Zefiros-Software/zpm2/1.0.0-beta/init",
				path = "modules-test/Zefiros-Software/zpm2/1.0.0-beta", 
				version = "1.0.0-beta"
			},
			{
				loader = "modules-test/Zefiros-Software/zpm2/0.0.1/init",
				path = "modules-test/Zefiros-Software/zpm2/0.0.1", 
				version = "0.0.1"
			},
			{
				loader = "modules-test/Zefiros-Software/zpm/3.0.0/init",
				path = "modules-test/Zefiros-Software/zpm/3.0.0",
				version = "3.0.0"
			},
			{
				loader = "modules-test/Zefiros-Software/zpm/1.0.0-alpha/init",
				path = "modules-test/Zefiros-Software/zpm/1.0.0-alpha",
				version = "1.0.0-alpha"
			},
			{
				loader = "modules-test/Zefiros-Software/zpm/0.0.1/init",
				path = "modules-test/Zefiros-Software/zpm/0.0.1",
				version = "0.0.1"
			}
		} ) 
		
		-- cleanup
		os.rmdir( "modules-test" )
		
		u.assertFalse( os.isdir( "modules-test" ) ) 
		bootstrap._dirModules = dirMods
	
    end
	
    function TestBootstrap:testListModulesTags_Mixed()

		-- init
		local dirMods = bootstrap._dirModules
		bootstrap._dirModules = "./modules-test"
		
		local dirs = { 
			"modules-test/Zefiros-Software/zpm/1.0.0-beta", 
			"modules-test/Zefiros-Software/zpm/1.0.0-alpha", 
			"modules-test/Zefiros-Software/zpm/0.0.1", 
			"modules-test/Zefiros-Software/zpm/3.0.0",
			
			"modules-test/Zefiros-Software/zpm2/1.0.0-beta", 
			"modules-test/Zefiros-Software/zpm2/0.0.1", 
			"modules-test/Zefiros-Software/zpm2/2.0.0",
			
			"modules-test/Zefiros-Softwarefe/df/1.5.4-ga", 
			"modules-test/Zefiros-Softwarefe/df/0.3.1", 
			"modules-test/Zefiros-Softwarefe/df/3.4.0"
		}
		
		for i, dir in ipairs( dirs ) do
			
			u.assertFalse( os.isdir( dir ) )			
			assert( os.mkdir( dir ) )
			u.assertTrue( os.isdir( dir ) )
			
			if i ~= 1 then
				local file = io.open( dir .. "/init.lua", "w" )
				file:close()
			end
		end
		
		-- test
		
		local tags = bootstrap.listModulesTags()
		u.assertEquals( #tags, 9 )
		u.assertItemsEquals( tags, {			
			{
				loader = "modules-test/Zefiros-Softwarefe/df/3.4.0/init",
				path = "modules-test/Zefiros-Softwarefe/df/3.4.0",
				version = "3.4.0"
			},
			{
				loader = "modules-test/Zefiros-Softwarefe/df/1.5.4-ga/init",
				path = "modules-test/Zefiros-Softwarefe/df/1.5.4-ga", 
				version = "1.5.4-ga"
			},
			{
				loader = "modules-test/Zefiros-Softwarefe/df/0.3.1/init",
				path = "modules-test/Zefiros-Softwarefe/df/0.3.1", 
				version = "0.3.1"
			},
			{
				loader = "modules-test/Zefiros-Software/zpm2/2.0.0/init",
				path = "modules-test/Zefiros-Software/zpm2/2.0.0",
				version = "2.0.0"
			},
			{
				loader = "modules-test/Zefiros-Software/zpm2/1.0.0-beta/init",
				path = "modules-test/Zefiros-Software/zpm2/1.0.0-beta", 
				version = "1.0.0-beta"
			},
			{
				loader = "modules-test/Zefiros-Software/zpm2/0.0.1/init",
				path = "modules-test/Zefiros-Software/zpm2/0.0.1", 
				version = "0.0.1"
			},
			{
				loader = "modules-test/Zefiros-Software/zpm/3.0.0/init",
				path = "modules-test/Zefiros-Software/zpm/3.0.0",
				version = "3.0.0"
			},
			{
				loader = "modules-test/Zefiros-Software/zpm/1.0.0-alpha/init",
				path = "modules-test/Zefiros-Software/zpm/1.0.0-alpha",
				version = "1.0.0-alpha"
			},
			{
				loader = "modules-test/Zefiros-Software/zpm/0.0.1/init",
				path = "modules-test/Zefiros-Software/zpm/0.0.1",
				version = "0.0.1"
			}
		} ) 
		
		-- cleanup
		os.rmdir( "modules-test" )
		
		u.assertFalse( os.isdir( "modules-test" ) ) 
		bootstrap._dirModules = dirMods
	
    end
	
    function TestBootstrap:testListModulesTags_MatchVendor()

		-- init
		local dirMods = bootstrap._dirModules
		bootstrap._dirModules = "./modules-test"
		
		local dirs = { 
			"modules-test/Zefiros-Software/zpm/head", 
			"modules-test/Zefiros-Software/zpm/1.0.0-alpha", 
			"modules-test/Zefiros-Software/zpm/0.0.1", 
			"modules-test/Zefiros-Software/zpm/3.0.0",
			
			"modules-test/Zefiros-Software/zpm2/1.0.0-beta", 
			"modules-test/Zefiros-Software/zpm2/0.0.1", 
			"modules-test/Zefiros-Software/zpm2/2.0.0",
			
			"modules-test/Zefiros_Softwarefe/df/1.5.4-ga", 
			"modules-test/Zefiros_Softwarefe/df/0.3.1", 
			"modules-test/Zefiros_Softwarefe/df/3.4.0"
		}
		
		for _, dir in ipairs( dirs ) do
						
			u.assertFalse( os.isdir( dir ) )
			assert( os.mkdir( dir ) )
			u.assertTrue( os.isdir( dir ) )
			
			local file = io.open( dir .. "/init.lua", "w" )
			file:close()
		end
		
		-- test
		
		local tags = bootstrap.listModulesTags( "Zefiros_Softwarefe" )
		u.assertEquals( #tags, 3 )
		u.assertItemsEquals( tags, {			
			{
				loader = "modules-test/Zefiros_Softwarefe/df/3.4.0/init",
				path = "modules-test/Zefiros_Softwarefe/df/3.4.0",
				version = "3.4.0"
			},
			{
				loader = "modules-test/Zefiros_Softwarefe/df/1.5.4-ga/init",
				path = "modules-test/Zefiros_Softwarefe/df/1.5.4-ga", 
				version = "1.5.4-ga"
			},
			{
				loader = "modules-test/Zefiros_Softwarefe/df/0.3.1/init",
				path = "modules-test/Zefiros_Softwarefe/df/0.3.1", 
				version = "0.3.1"
			}
		} ) 
		
		-- cleanup
		os.rmdir( "modules-test" )
		
		u.assertFalse( os.isdir( "modules-test" ) ) 
		bootstrap._dirModules = dirMods
	
    end
	
    function TestBootstrap:testListModulesTags_MatchModule()

		-- init
		local dirMods = bootstrap._dirModules
		bootstrap._dirModules = "./modules-test"
		
		local dirs = { 
			"modules-test/Zefiros-Software/zpm/head", 
			"modules-test/Zefiros-Software/zpm/1.0.0-alpha", 
			"modules-test/Zefiros-Software/zpm/0.0.1", 
			"modules-test/Zefiros-Software/zpm/3.0.0",
			
			"modules-test/Zefiros-Software/zpm2/1.0.0-beta", 
			"modules-test/Zefiros-Software/zpm2/0.0.1", 
			"modules-test/Zefiros-Software/zpm2/2.0.0",
			
			"modules-test/Zefiros-Softwarefe/df/1.5.4-ga", 
			"modules-test/Zefiros-Softwarefe/df/0.3.1", 
			"modules-test/Zefiros-Softwarefe/df/3.4.0"
		}
		
		for _, dir in ipairs( dirs ) do
			
			u.assertFalse( os.isdir( dir ) )
			assert( os.mkdir( dir ) )
			u.assertTrue( os.isdir( dir ) )
			
			local file = io.open( dir .. "/init.lua", "w" )
			file:close()
		end
		
		-- test
		
		local tags = bootstrap.listModulesTags( "*", "zpm" )
		u.assertEquals( #tags, 3 )
		u.assertItemsEquals( tags, {	
			{
				loader = "modules-test/Zefiros-Software/zpm/3.0.0/init",
				path = "modules-test/Zefiros-Software/zpm/3.0.0",
				version = "3.0.0"
			},
			{
				loader = "modules-test/Zefiros-Software/zpm/1.0.0-alpha/init",
				path = "modules-test/Zefiros-Software/zpm/1.0.0-alpha",
				version = "1.0.0-alpha"
			},
			{
				loader = "modules-test/Zefiros-Software/zpm/0.0.1/init",
				path = "modules-test/Zefiros-Software/zpm/0.0.1",
				version = "0.0.1"
			}
		} ) 
		
		-- cleanup
		os.rmdir( "modules-test" )
		
		u.assertFalse( os.isdir( "modules-test" ) ) 
		bootstrap._dirModules = dirMods
	
    end
		
	
    function TestBootstrap:testListModulesHead_NoInit()

		-- init
		local dirMods = bootstrap._dirModules
		bootstrap._dirModules = "./modules-test"
		
		local dirs = { 
			"modules-test/Zefiros-Software/zpm/head",	
			"modules-test/Zefiros-Software/zpm2/head",	
			"modules-test/Zefiros-Softwarefe/df/head" 
		}
		
		for _, dir in ipairs( dirs ) do
			
			u.assertFalse( os.isdir( dir ) )
			assert( os.mkdir( dir ) )
			u.assertTrue( os.isdir( dir ) )
		end
		
		-- test
		
		local tags = bootstrap.listModulesHead()
		u.assertEquals( #tags, 0 )
		os.rmdir( "modules-test" )
		
		u.assertFalse( os.isdir( "modules-test" ) ) 
		bootstrap._dirModules = dirMods
	
    end	
	
    function TestBootstrap:testListModulesHead_Init()

		-- init
		local dirMods = bootstrap._dirModules
		bootstrap._dirModules = "./modules-test"
		
		local dirs = { 
			"modules-test/Zefiros-Software/zpm/head",	
			"modules-test/Zefiros-Software/zpm2/head",	
			"modules-test/Zefiros-Softwarefe/df/head" 
		}
		
		for _, dir in ipairs( dirs ) do
			
			u.assertFalse( os.isdir( dir ) )
			assert( os.mkdir( dir ) )
			u.assertTrue( os.isdir( dir ) )
			
			local file = io.open( dir .. "/init.lua", "w" )
			file:close()
		end
		
		-- test
		
		local tags = bootstrap.listModulesHead()
		u.assertEquals( #tags, 3 )
		u.assertItemsEquals( tags, {
			"modules-test/Zefiros-Software/zpm/head/init",
			"modules-test/Zefiros-Software/zpm2/head/init",
			"modules-test/Zefiros-Softwarefe/df/head/init"
		} ) 
		os.rmdir( "modules-test" )
		
		u.assertFalse( os.isdir( "modules-test" ) ) 
		bootstrap._dirModules = dirMods
	
    end
	
    function TestBootstrap:testListModulesHead_InitModule()

		-- init
		local dirMods = bootstrap._dirModules
		bootstrap._dirModules = "./modules-test"
		
		local dirs = { 
			"modules-test/Zefiros-Software/zpm/head",	
			"modules-test/Zefiros/zpm/head",	
			"modules-test/Zefiros-Softwarefe/zpm/head" 
		}
		
		for _, dir in ipairs( dirs ) do
			
			u.assertFalse( os.isdir( dir ) )
			assert( os.mkdir( dir ) )
			u.assertTrue( os.isdir( dir ) )
			
			local file = io.open( dir .. "/zpm.lua", "w" )
			file:close()
		end
		
		-- test
		
		local tags = bootstrap.listModulesHead()
		u.assertEquals( #tags, 3 )
		u.assertItemsEquals( tags, {
			"modules-test/Zefiros-Software/zpm/head/zpm",
			"modules-test/Zefiros/zpm/head/zpm",
			"modules-test/Zefiros-Softwarefe/zpm/head/zpm"
		} ) 
		os.rmdir( "modules-test" )
		
		u.assertFalse( os.isdir( "modules-test" ) ) 
		bootstrap._dirModules = dirMods
	
    end
	
    function TestBootstrap:testListModulesHead_VersionIgnored()

		-- init
		local dirMods = bootstrap._dirModules
		bootstrap._dirModules = "./modules-test"
		
		local dirs = { 
			"modules-test/Zefiros-Software/zpm/head",	
			"modules-test/Zefiros/zpm/head",	
			"modules-test/Zefiros-Softwarefe/zpm/head",	
			"modules-test/Zefiros-Softwareffe/zpm/0.0.1" 
		}
		
		for _, dir in ipairs( dirs ) do
			
			u.assertFalse( os.isdir( dir ) )
			assert( os.mkdir( dir ) )
			u.assertTrue( os.isdir( dir ) )
			
			local file = io.open( dir .. "/zpm.lua", "w" )
			file:close()
		end
		
		-- test
		
		local tags = bootstrap.listModulesHead()
		u.assertEquals( #tags, 3 )
		u.assertItemsEquals( tags, {
			"modules-test/Zefiros-Software/zpm/head/zpm",
			"modules-test/Zefiros/zpm/head/zpm",
			"modules-test/Zefiros-Softwarefe/zpm/head/zpm"
		} ) 
		os.rmdir( "modules-test" )
		
		u.assertFalse( os.isdir( "modules-test" ) ) 
		bootstrap._dirModules = dirMods
	
    end
	
    function TestBootstrap:testListModulesHead_MatchVendor()

		-- init
		local dirMods = bootstrap._dirModules
		bootstrap._dirModules = "./modules-test"
		
		local dirs = { 
			"modules-test/Zefiros-Software/zpm/head",	
			"modules-test/Zefiros/zpm/head",	
			"modules-test/Zefiros_Softwarefe/zpm/head"
		}
		
		for _, dir in ipairs( dirs ) do
			
			u.assertFalse( os.isdir( dir ) )
			assert( os.mkdir( dir ) )
			u.assertTrue( os.isdir( dir ) )
			
			local file = io.open( dir .. "/zpm.lua", "w" )
			file:close()
		end
		
		-- test
		
		local tags = bootstrap.listModulesHead()
		u.assertEquals( #tags, 3 )
		u.assertItemsEquals( tags, {
			"modules-test/Zefiros-Software/zpm/head/zpm",
			"modules-test/Zefiros/zpm/head/zpm",
			"modules-test/Zefiros_Softwarefe/zpm/head/zpm"
		} ) 
		os.rmdir( "modules-test" )
		
		u.assertFalse( os.isdir( "modules-test" ) ) 
		bootstrap._dirModules = dirMods
	
    end
	
    function TestBootstrap:testCheckVersion_Basic()
	
		u.assertTrue( bootstrap.checkVersion( premake.checkVersion, "0.5.0", ">0.4.0" ) )
		u.assertFalse( bootstrap.checkVersion( premake.checkVersion, "0.5.0", ">0.5.0" ) )
	
    end
	
    function TestBootstrap:testCheckVersion_Multiple()
		
		u.assertTrue( bootstrap.checkVersion( premake.checkVersion, "0.5.0", "<=0.0.0 || >0.4.0" ) )
		u.assertFalse( bootstrap.checkVersion( premake.checkVersion, "0.5.0", "<=0.0.0 || >0.5.0" ) )
	
    end
	
    function TestBootstrap:testCheckVersion_Fix()
		
		u.assertTrue( bootstrap.checkVersion( premake.checkVersion, "0.5", "<=0.0.0 || >0.4.0" ) )
		u.assertFalse( bootstrap.checkVersion( premake.checkVersion, "0.5", "<=0.0.0 || >0.5.0" ) )
	
    end
	
    function TestBootstrap:testCheckVersion_Trim()

		u.assertTrue( bootstrap.checkVersion( premake.checkVersion, "0.5.0", "<=0.0.0  ||   >0.4.0" ) )
		u.assertFalse( bootstrap.checkVersion( premake.checkVersion, "0.5.0", "<=0.0.0  ||   >0.5.0" ) )
	
    end
	
    function TestBootstrap:testCheckVersion_Tripple()

		u.assertTrue( bootstrap.checkVersion( premake.checkVersion, "0.5.0", "<=0.0.0  ||>1.0.0  ||   >0.4.0" ) )
		u.assertFalse( bootstrap.checkVersion( premake.checkVersion, "0.5.0", "<=0.0.0  ||>1.0.0  ||   >0.5.0" ) )
	
    end
	
    function TestBootstrap:testCheckVersion_Head()

		u.assertTrue( bootstrap.checkVersion( premake.checkVersion, "@head", "@head" ) )
		u.assertTrue( bootstrap.checkVersion( premake.checkVersion, "@head", "<=0.0.0  ||>1.0.0  ||@head" ) )
		u.assertFalse( bootstrap.checkVersion( premake.checkVersion, "0.2.0", "<=0.0.0  ||>1.0.0  ||@head" ) )
		u.assertFalse( bootstrap.checkVersion( premake.checkVersion, "@head", "<=0.0.0  ||>1.0.0  ||   >0.5.0" ) )
	
    end
	
    function TestBootstrap:testFixVersion_Basic()
	
		u.assertEquals( bootstrap.fixVersion( "0.5" ), "0.5.0" )	
		u.assertEquals( bootstrap.fixVersion( "5" ), "5.0.0" )	
		u.assertEquals( bootstrap.fixVersion( "0.5.1" ), "0.5.1" )
		u.assertEquals( bootstrap.fixVersion( "0.5.1.2" ), "0.5.1.2" )
	
    end
	
    function TestBootstrap:testRequireOld()

		local oldPath = package.path
		-- init
		local dirMods = bootstrap._dirModules
		bootstrap._dirModules = "./modules-test"
			
		assert( os.mkdir( bootstrap._dirModules ) )
		u.assertTrue( os.isdir( bootstrap._dirModules ) )
		
			
		local file = io.open( bootstrap._dirModules .. "/testRequireOld.lua", "w" )
		file:write([[
			return "bar"
		]])
		file:close()
		
		local mo = bootstrap.requireVersionsOld( require, bootstrap._dirModules .. "/testRequireOld" )
		
		-- test
		u.assertEquals( mo, "bar" )
		
		os.rmdir( bootstrap._dirModules )
		
		u.assertFalse( os.isdir( bootstrap._dirModules ) ) 
		bootstrap._dirModules = dirMods
	
		-- path correctly restored
		u.assertEquals( package.path, oldPath )
    end
	
    function TestBootstrap:testRequireOld_Remember()

		local oldPath = package.path

		-- init
		local dirMods = bootstrap._dirModules
		bootstrap._dirModules = "./modules-test"
			
		assert( os.mkdir( bootstrap._dirModules ) )
		u.assertTrue( os.isdir( bootstrap._dirModules ) )
		u.assertFalse( os.isfile( bootstrap._dirModules .. "/testRequireOld.lua" ) )
		
		local mo = bootstrap.requireVersionsOld( require, bootstrap._dirModules .. "/testRequireOld" )
		
		-- test
		u.assertEquals( mo, "bar" )
		
		os.rmdir( bootstrap._dirModules )
		
		u.assertFalse( os.isdir( bootstrap._dirModules ) ) 
		bootstrap._dirModules = dirMods
	
		-- path correctly restored
		u.assertEquals( package.path, oldPath )
	
    end
	
    function TestBootstrap:testRequireOld_Remember2()

		local oldPath = package.path

		-- init
		local dirMods = bootstrap._dirModules
		bootstrap._dirModules = "./modules-test"
			
		assert( os.mkdir( bootstrap._dirModules ) )
		u.assertTrue( os.isdir( bootstrap._dirModules ) )
					
		local file = io.open( bootstrap._dirModules .. "/testRequireOld.lua", "w" )
		file:write([[
			return "barf"
		]])
		file:close()
		
		local mo = bootstrap.requireVersionsOld( require, bootstrap._dirModules .. "/testRequireOld" )
		
		-- test
		u.assertEquals( mo, "bar" )
		
		os.rmdir( bootstrap._dirModules )
		
		u.assertFalse( os.isdir( bootstrap._dirModules ) ) 
		bootstrap._dirModules = dirMods
	
		-- path correctly restored
		u.assertEquals( package.path, oldPath )
	
    end
	
    function TestBootstrap:testRequireOld_LuaRockStyle()

		local oldPath = package.path
		-- init
		local dirMods = bootstrap._dirModules
		bootstrap._dirModules = "./modules-test"
			
		assert( os.mkdir( bootstrap._dirModules ) )
		u.assertTrue( os.isdir( bootstrap._dirModules ) )
			
		local file = io.open( bootstrap._dirModules .. "/testRequireOld_LuaRockStyle.lua", "w" )
		file:write([[
			return require( "testRequireOld_LuaRockStyle.bar" )
		]])
		file:close()
		
			
		file2 = io.open( bootstrap._dirModules .. "/testRequireOld_LuaRockStyle/bar.lua", "w" )
		file2:write([[
			return require( "testRequireOld_LuaRockStyle.bar2" )
		]])
		file2:close()
		
			
		file3 = io.open( bootstrap._dirModules .. "/testRequireOld_LuaRockStyle/bar2.lua", "w" )
		file3:write([[
			return "bar2"
		]])
		file3:close()
		
		local mo = bootstrap.requireVersionsOld( require, bootstrap._dirModules .. "/testRequireOld_LuaRockStyle" )
		
		-- test
		u.assertEquals( mo, "bar2" )
		
		os.rmdir( bootstrap._dirModules )
		
		u.assertFalse( os.isdir( bootstrap._dirModules ) ) 
		bootstrap._dirModules = dirMods
	
	
		-- path correctly restored
		u.assertEquals( package.path, oldPath )
    end
	
    function TestBootstrap:testRequireOld_NoFile()

		local oldPath = package.path
		-- init
		local dirMods = bootstrap._dirModules
		bootstrap._dirModules = "./modules-test"
		u.assertFalse( os.isfile( bootstrap._dirModules .. "/foo3.lua" ) )
			
		assert( os.mkdir( bootstrap._dirModules ) )
		u.assertTrue( os.isdir( bootstrap._dirModules ) )
		
		u.assertErrorMsgContains( "module './modules-test/foo3' not found", bootstrap.requireVersionsOld, require, bootstrap._dirModules .. "/foo3" )
		
		os.rmdir( bootstrap._dirModules )
		
		u.assertFalse( os.isdir( bootstrap._dirModules ) ) 
		bootstrap._dirModules = dirMods
	
	
		-- path correctly restored
		u.assertEquals( package.path, oldPath )
    end
	
    function TestBootstrap:testRequireOld_Fail()

		local oldPath = package.path
		-- init
		local dirMods = bootstrap._dirModules
		bootstrap._dirModules = "./modules-test"
			
		assert( os.mkdir( bootstrap._dirModules ) )
		u.assertTrue( os.isdir( bootstrap._dirModules ) )
		
			
		local file = io.open( bootstrap._dirModules .. "/foo4.lua", "w" )
		file:write([[
			return "barf
		]])
		file:close()
		
		u.assertErrorMsgContains( "unfinished string near '\"barf'", bootstrap.requireVersionsOld, require, bootstrap._dirModules .. "/foo4" )
		
		os.rmdir( bootstrap._dirModules )
		
		u.assertFalse( os.isdir( bootstrap._dirModules ) ) 
		bootstrap._dirModules = dirMods
	
	
		-- path correctly restored
		u.assertEquals( package.path, oldPath )
    end
	
	
	
	
	
	
    function TestBootstrap:testRequireVersionHead()

		local oldPath = package.path
		-- init
		local dirMods = bootstrap._dirModules
		bootstrap._dirModules = "./modules-test"
		
		local dir = bootstrap._dirModules .. "/Zefiros-Software/zpm/head"
		
		assert( os.mkdir( dir ) )
		u.assertTrue( os.isdir( dir ) )
		
			
		local file = io.open( dir .. "/zpm.lua", "w" )
		file:write([[
			return "bar"
		]])
		file:close()
		
		local mo, found = bootstrap.requireVersionHead( require, {"Zefiros-Software", "zpm"} )
		
		-- test
		u.assertEquals( mo, "bar" )
		u.assertTrue( found )
		
		os.rmdir( bootstrap._dirModules )
		
		u.assertFalse( os.isdir( bootstrap._dirModules ) ) 
		bootstrap._dirModules = dirMods
	
	
		-- path correctly restored
		u.assertEquals( package.path, oldPath )
    end	
	
    function TestBootstrap:testRequireVersionHead_Underscore()

		local oldPath = package.path
		-- init
		local dirMods = bootstrap._dirModules
		bootstrap._dirModules = "./modules-test"
		
		local dir = bootstrap._dirModules .. "/Zefiros-Software/zpm_/head"
		
		assert( os.mkdir( dir ) )
		u.assertTrue( os.isdir( dir ) )
		
			
		local file = io.open( dir .. "/zpm_.lua", "w" )
		file:write([[
			return "bar"
		]])
		file:close()
		
		local mo, found = bootstrap.requireVersionHead( require, {"Zefiros-Software", "zpm_"} )
		
		-- test
		u.assertEquals( mo, "bar" )
		u.assertTrue( found )
		
		os.rmdir( bootstrap._dirModules )
		
		u.assertFalse( os.isdir( bootstrap._dirModules ) ) 
		bootstrap._dirModules = dirMods
	
	
		-- path correctly restored
		u.assertEquals( package.path, oldPath )
    end
	
    function TestBootstrap:testRequireVersionHead_Dash()

		local oldPath = package.path
		-- init
		local dirMods = bootstrap._dirModules
		bootstrap._dirModules = "./modules-test"
		
		local dir = bootstrap._dirModules .. "/Zefiros-Software/zpm-/head"
		
		assert( os.mkdir( dir ) )
		u.assertTrue( os.isdir( dir ) )
		
			
		local file = io.open( dir .. "/zpm-.lua", "w" )
		file:write([[
			return "bar"
		]])
		file:close()
		
		local mo, found = bootstrap.requireVersionHead( require, {"Zefiros-Software", "zpm-"} )
		
		-- test
		u.assertEquals( mo, "bar" )
		u.assertTrue( found )
		
		os.rmdir( bootstrap._dirModules )
		
		u.assertFalse( os.isdir( bootstrap._dirModules ) ) 
		bootstrap._dirModules = dirMods
	
	
		-- path correctly restored
		u.assertEquals( package.path, oldPath )
    end
	
	function TestBootstrap:testRequireVersionHead_CWD()
		
		local oldPath = package.path
		
		local dirMods = bootstrap._dirModules
		bootstrap._dirModules = "."
		local dir = "Zefiros-Software/testRequireVersionHead_CWD/head"
		
		assert( os.mkdir( dir ) )
		u.assertTrue( os.isdir( dir ) )
					
		local file = io.open( dir .. "/testRequireVersionHead_CWD.lua", "w" )
		file:write([[
			return "bar"
		]])
		file:close()
		
		local mo, found = bootstrap.requireVersionHead( require, {"Zefiros-Software", "testRequireVersionHead_CWD"} )
		
		-- test
		u.assertEquals( mo, "bar" )
		u.assertTrue( found )
		
		os.rmdir( "Zefiros-Software" )
		
		u.assertFalse( os.isdir( dir ) )
	
		bootstrap._dirModules = dirMods
	
		-- path correctly restored
		u.assertEquals( package.path, oldPath )
    end
	
	function TestBootstrap:testRequireVersionHead_Multiple()

		local oldPath = package.path
		
		-- init
		local dirMods = bootstrap._dirModules
		bootstrap._dirModules = "./modules-test"
		
		local dir = bootstrap._dirModules .. "/Zefiros-Software/testRequireVersionHead_Multiple/head"
		local dir2 = bootstrap._dirModules .. "/Zefiros-Software/testRequireVersionHead_Multiple2/head"
		
		assert( os.mkdir( dir ) )
		u.assertTrue( os.isdir( dir ) )
		
		assert( os.mkdir( dir2 ) )
		u.assertTrue( os.isdir( dir2 ) )
					
		local file = io.open( dir .. "/testRequireVersionHead_Multiple.lua", "w" )
		file:write([[
			return "bar"
		]])
		file:close()
					
		file2 = io.open( dir2 .. "/testRequireVersionHead_Multiple2.lua", "w" )
		file2:write([[
			return "bar2"
		]])
		file2:close()
		
		local mo, found = bootstrap.requireVersionHead( require, {"Zefiros-Software", "*"} )
		
		-- test
		u.assertEquals( mo, "bar" )
		u.assertTrue( found )
		
		os.rmdir( bootstrap._dirModules )
		
		u.assertFalse( os.isdir( bootstrap._dirModules ) )
		bootstrap._dirModules = dirMods
	
		-- path correctly restored
		u.assertEquals( package.path, oldPath )
	
    end
	
	function TestBootstrap:testRequireVersionHead_Multiple2()

		local oldPath = package.path
		
		-- init
		local dirMods = bootstrap._dirModules
		bootstrap._dirModules = "./modules-test"
			
		local dir = bootstrap._dirModules .. "/Zefiros-Software/testRequireVersionHead_Multiple3/head"
		local dir2 = bootstrap._dirModules .. "/Zefiros-Software/testRequireVersionHead_Multiple4/head"
		
		assert( os.mkdir( dir2 ) )
		u.assertTrue( os.isdir( dir2 ) )
		
		assert( os.mkdir( dir ) )
		u.assertTrue( os.isdir( dir ) )
					
		file2 = io.open( dir2 .. "/testRequireVersionHead_Multiple4.lua", "w" )
		file2:write([[
			return "bar2"
		]])
		file2:close()
					
		local file = io.open( dir .. "/testRequireVersionHead_Multiple3.lua", "w" )
		file:write([[
			return "bar"
		]])
		file:close()
		
		local mo, found = bootstrap.requireVersionHead( require, {"Zefiros-Software", "*"} )
		
		-- test
		u.assertEquals( mo, "bar" )
		u.assertTrue( found )
		
		os.rmdir( bootstrap._dirModules )
		
		u.assertFalse( os.isdir( bootstrap._dirModules ) )
		bootstrap._dirModules = dirMods
	
	
		-- path correctly restored
		u.assertEquals( package.path, oldPath )
    end
	
    function TestBootstrap:testRequireVersionHead_Remember()

		local oldPath = package.path
		
		-- init
		local dirMods = bootstrap._dirModules
		bootstrap._dirModules = "./modules-test"
		
		local dir = bootstrap._dirModules .. "/Zefiros-Software/testRequireVersionHead_Remember/head"
		
		assert( os.mkdir( dir ) )
		u.assertTrue( os.isdir( dir ) )
		u.assertFalse( os.isfile( dir .. "/zpm.lua" ) )
		
		u.assertErrorMsgContains( "Module with vendor 'Zefiros-Software' and name 'testRequireVersionHead_Remember' not found", bootstrap.requireVersionHead, require, {"Zefiros-Software", "testRequireVersionHead_Remember"} )
				
		os.rmdir( bootstrap._dirModules )
		
		u.assertFalse( os.isdir( bootstrap._dirModules ) ) 
		bootstrap._dirModules = dirMods
	
		-- path correctly restored
		u.assertEquals( package.path, oldPath )
	
    end	
	
    function TestBootstrap:testRequireVersionHead_LuaRockStyle()

		local oldPath = package.path
		
		-- init
		local dirMods = bootstrap._dirModules
		bootstrap._dirModules = "./modules-test"
		
		local dir = bootstrap._dirModules .. "/Zefiros-Software/testRequireVersionHead_LuaRockStyle/head"
			
		assert( os.mkdir( dir ) )
		u.assertTrue( os.isdir( dir ) )
			
		local file = io.open( dir .. "/testRequireVersionHead_LuaRockStyle.lua", "w" )
		file:write([[
			return require( "testRequireVersionHead_LuaRockStyle.bar" )
		]])
		file:close()
		
			
		file2 = io.open( dir .. "/testRequireVersionHead_LuaRockStyle/bar.lua", "w" )
		file2:write([[
			return require( "testRequireVersionHead_LuaRockStyle.bar2" )
		]])
		file2:close()
		
			
		file3 = io.open( dir .. "/testRequireVersionHead_LuaRockStyle/bar2.lua", "w" )
		file3:write([[
			return "barsss2"
		]])
		file3:close()
		
		local mo, found = bootstrap.requireVersionHead( require, {"Zefiros-Software", "testRequireVersionHead_LuaRockStyle"} )
		
		-- test
		u.assertEquals( mo, "barsss2" )
		u.assertTrue( found )
		
		os.rmdir( bootstrap._dirModules )
		
		u.assertFalse( os.isdir( bootstrap._dirModules ) ) 
		bootstrap._dirModules = dirMods
	
		-- path correctly restored
		u.assertEquals( package.path, oldPath )
	
    end
	
    function TestBootstrap:testRequireVersionHead_LuaRockStyle_Absolute()

		local oldPath = package.path
		
		-- init
		local dirMods = bootstrap._dirModules
		bootstrap._dirModules = path.join( os.getcwd(), "modules-test" )
		
		local dir = bootstrap._dirModules .. "/Zefiros-Software/testRequireVersionHead_LuaRockStyle_Absolute/head"
			
		assert( os.mkdir( dir ) )
		u.assertTrue( os.isdir( dir ) )
			
		local file = io.open( dir .. "/testRequireVersionHead_LuaRockStyle_Absolute.lua", "w" )
		file:write([[
			return require( "testRequireVersionHead_LuaRockStyle_Absolute.bar" )
		]])
		file:close()
		
			
		file2 = io.open( dir .. "/testRequireVersionHead_LuaRockStyle_Absolute/bar.lua", "w" )
		file2:write([[
			return require( "testRequireVersionHead_LuaRockStyle_Absolute.bar2" )
		]])
		file2:close()
		
			
		file3 = io.open( dir .. "/testRequireVersionHead_LuaRockStyle_Absolute/bar2.lua", "w" )
		file3:write([[
			return "barsss2"
		]])
		file3:close()
		
		local mo, found = bootstrap.requireVersionHead( require, {"Zefiros-Software", "testRequireVersionHead_LuaRockStyle_Absolute"} )
		
		-- test
		u.assertEquals( mo, "barsss2" )
		u.assertTrue( found )
		
		os.rmdir( bootstrap._dirModules )
		
		u.assertFalse( os.isdir( bootstrap._dirModules ) ) 
		bootstrap._dirModules = dirMods
	
		-- path correctly restored
		u.assertEquals( package.path, oldPath )
	
    end
	
	
    function TestBootstrap:testRequireVersionHead_NoFile()

		local oldPath = package.path
		
		-- init
		local dirMods = bootstrap._dirModules
		bootstrap._dirModules = "./modules-test"
		
		local dir = bootstrap._dirModules .. "/Zefiros-Software/testRequireVersionHead_NoFile/head"
		
		assert( os.mkdir( dir ) )
		u.assertTrue( os.isdir( dir ) )
		u.assertFalse( os.isfile( dir .. "/testRequireVersionHead_NoFile.lua" ) )
		
		u.assertErrorMsgContains( "Module with vendor 'Zefiros-Software' and name 'testRequireVersionHead_NoFile' not found", bootstrap.requireVersionHead, require, {"Zefiros-Software", "testRequireVersionHead_NoFile"} )
				
		os.rmdir( bootstrap._dirModules )
		
		u.assertFalse( os.isdir( bootstrap._dirModules ) ) 
		bootstrap._dirModules = dirMods
	
		-- path correctly restored
		u.assertEquals( package.path, oldPath )
	
    end	
	
	
	
    function TestBootstrap:testRequireVersionHead_Fail()

		local oldPath = package.path
		-- init
		local dirMods = bootstrap._dirModules
		bootstrap._dirModules = "./modules-test"
		
		local dir = bootstrap._dirModules .. "/Zefiros_Software/testRequireVersionHead_Fail/head"
		
		assert( os.mkdir( dir ) )
		u.assertTrue( os.isdir( dir ) )
		
			
		local file = io.open( dir .. "/testRequireVersionHead_Fail.lua", "w" )
		file:write([[
			return "bar
		]])
		file:close()
		
		u.assertErrorMsgContains( "unfinished string near '\"bar'", bootstrap.requireVersionHead, require, {"Zefiros_Software", "testRequireVersionHead_Fail"} )
			
		os.rmdir( bootstrap._dirModules )
		
		u.assertFalse( os.isdir( bootstrap._dirModules ) ) 
		bootstrap._dirModules = dirMods
	
	
		-- path correctly restored
		u.assertEquals( package.path, oldPath )
    end
	
	
	
	function TestBootstrap:testRequireVersionsNew()

		local oldPath = package.path

		-- init
		local dirMods = bootstrap._dirModules
		bootstrap._dirModules = "./modules-test"
		
		local dir = bootstrap._dirModules .. "/Zefiros-Software/testRequireVersionsNew/0.0.1"
		
		assert( os.mkdir( dir ) )
		u.assertTrue( os.isdir( dir ) )
		
			
		local file = io.open( dir .. "/testRequireVersionsNew.lua", "w" )
		file:write([[
			return "testRequireVersionsNew"
		]])
		file:close()
		
		local mo = bootstrap.requireVersionsNew( require, {"Zefiros-Software", "testRequireVersionsNew"} )
		
		-- test
		u.assertEquals( mo, "testRequireVersionsNew" )
		
		os.rmdir( bootstrap._dirModules )
		
		u.assertFalse( os.isdir( bootstrap._dirModules ) ) 
		bootstrap._dirModules = dirMods
	
		-- path correctly restored
		u.assertEquals( package.path, oldPath )
	
    end
	
	function TestBootstrap:testRequireVersionsNew_Underscore()

		local oldPath = package.path

		-- init
		local dirMods = bootstrap._dirModules
		bootstrap._dirModules = "./modules-testf"
		
		local dir = bootstrap._dirModules .. "/Zefiros-Software/testRequireVersionsNew_Underscore/0.0.1"
		
		assert( os.mkdir( dir ) )
		u.assertTrue( os.isdir( dir ) )
		
			
		local file = io.open( dir .. "/testRequireVersionsNew_Underscore.lua", "w" )
		file:write([[
			return "testRequireVersionsNew_Underscore"
		]])
		file:close()
		
		local mo = bootstrap.requireVersionsNew( require, {"Zefiros-Software", "testRequireVersionsNew_Underscore"} )
		
		-- test
		u.assertEquals( mo, "testRequireVersionsNew_Underscore" )
		
		os.rmdir( bootstrap._dirModules )
		
		u.assertFalse( os.isdir( bootstrap._dirModules ) ) 
		bootstrap._dirModules = dirMods
	
		-- path correctly restored
		u.assertEquals( package.path, oldPath )
	
    end
	
	function TestBootstrap:testRequireVersionsNew_Dash()

		local oldPath = package.path

		-- init
		local dirMods = bootstrap._dirModules
		bootstrap._dirModules = "./modules-testf"
		
		local dir = bootstrap._dirModules .. "/Zefiros-Software/testRequireVersionsNew-Dash/0.0.1"
		
		assert( os.mkdir( dir ) )
		u.assertTrue( os.isdir( dir ) )
		
			
		local file = io.open( dir .. "/testRequireVersionsNew-Dash.lua", "w" )
		file:write([[
			return "testRequireVersionsNew_Dash"
		]])
		file:close()
		
		local mo = bootstrap.requireVersionsNew( require, {"Zefiros-Software", "testRequireVersionsNew-Dash"} )
		
		-- test
		u.assertEquals( mo, "testRequireVersionsNew_Dash" )
		
		os.rmdir( bootstrap._dirModules )
		
		u.assertFalse( os.isdir( bootstrap._dirModules ) ) 
		bootstrap._dirModules = dirMods
	
		-- path correctly restored
		u.assertEquals( package.path, oldPath )
	
    end
	
	function TestBootstrap:testRequireVersionsNew_CWD()

		local oldPath = package.path

		-- init
		local dirMods = bootstrap._dirModules
		bootstrap._dirModules = "./"
		
		local dir = "./Zefiros_Software/testRequireVersionsNew_CWD/0.0.1"
		
		assert( os.mkdir( dir ) )
		u.assertTrue( os.isdir( dir ) )
		
			
		local file = io.open( dir .. "/testRequireVersionsNew_CWD.lua", "w" )
		file:write([[
			return "testRequireVersionsNew_CWD"
		]])
		file:close()
		
		local mo = bootstrap.requireVersionsNew( require, {"Zefiros_Software", "testRequireVersionsNew_CWD"} )
		
		-- test
		u.assertEquals( mo, "testRequireVersionsNew_CWD" )
		
		os.rmdir( "./Zefiros_Software" )		
		
		u.assertFalse( os.isdir( "./Zefiros_Software" ) ) 
		bootstrap._dirModules = dirMods
	
		-- path correctly restored
		u.assertEquals( package.path, oldPath )
	
    end
	
	function TestBootstrap:testRequireVersionsNew_Multiple()

		local oldPath = package.path

		-- init
		local dirMods = bootstrap._dirModules
		bootstrap._dirModules = "./modules-test"
		
		local dir = bootstrap._dirModules .. "/Zefiros-Software/testRequireVersionsNew_Multiple/0.0.1"
		local dir2 = bootstrap._dirModules .. "/Zefiros-Software/atestRequireVersionsNew_Multiple/0.1.1-alpha"
		
		assert( os.mkdir( dir ) )
		u.assertTrue( os.isdir( dir ) )
		
		assert( os.mkdir( dir2 ) )
		u.assertTrue( os.isdir( dir2 ) )
					
		local file = io.open( dir .. "/testRequireVersionsNew_Multiple.lua", "w" )
		file:write([[
			return "barrr"
		]])
		file:close()		
			
		local file2 = io.open( dir2 .. "/atestRequireVersionsNew_Multiple.lua", "w" )
		file2:write([[
			return "barrrf"
		]])
		file2:close()
		
		local mo = bootstrap.requireVersionsNew( require, {"Zefiros-Software", "*"} )
		
		-- test
		u.assertEquals( mo, "barrrf" )
		
		os.rmdir( bootstrap._dirModules )
		
		u.assertFalse( os.isdir( bootstrap._dirModules ) ) 
		bootstrap._dirModules = dirMods
	
		-- path correctly restored
		u.assertEquals( package.path, oldPath )
	
    end
	
	function TestBootstrap:testRequireVersionsNew_Multiple2()

		local oldPath = package.path

		-- init
		local dirMods = bootstrap._dirModules
		bootstrap._dirModules = "./modules-test"
		
		local dir = bootstrap._dirModules .. "/Zefiros-Software/atestRequireVersionsNew_Multiple2/0.0.1"
		local dir2 = bootstrap._dirModules .. "/Zefiros-Software/ztestRequireVersionsNew_Multiple2/0.1.1-alpha"
		
		assert( os.mkdir( dir ) )
		u.assertTrue( os.isdir( dir ) )
		
		assert( os.mkdir( dir2 ) )
		u.assertTrue( os.isdir( dir2 ) )		
			
		local file2 = io.open( dir2 .. "/ztestRequireVersionsNew_Multiple2.lua", "w" )
		file2:write([[
			return "barrrf"
		]])
		file2:close()
					
		local file = io.open( dir .. "/atestRequireVersionsNew_Multiple2.lua", "w" )
		file:write([[
			return "barrr"
		]])
		file:close()
		
		local mo = bootstrap.requireVersionsNew( require, {"Zefiros-Software", "*"} )
		
		-- test
		u.assertEquals( mo, "barrr" )
		
		os.rmdir( bootstrap._dirModules )
		
		u.assertFalse( os.isdir( bootstrap._dirModules ) ) 
		bootstrap._dirModules = dirMods
	
		-- path correctly restored
		u.assertEquals( package.path, oldPath )
	
    end
	
	function TestBootstrap:testRequireVersionsNew_Multiple_Version()

		local oldPath = package.path

		-- init
		local dirMods = bootstrap._dirModules
		bootstrap._dirModules = "./modules-test"
		
		local dir = bootstrap._dirModules .. "/Zefiros-Software/testRequireVersionsNew_Multiple_Version/0.0.1"
		local dir2 = bootstrap._dirModules .. "/Zefiros-Software/atestRequireVersionsNew_Multiple_Version/0.1.1-alpha"
		
		assert( os.mkdir( dir ) )
		u.assertTrue( os.isdir( dir ) )
		
		assert( os.mkdir( dir2 ) )
		u.assertTrue( os.isdir( dir2 ) )
					
		local file = io.open( dir .. "/testRequireVersionsNew_Multiple_Version.lua", "w" )
		file:write([[
			return "barrr"
		]])
		file:close()		
			
		local file2 = io.open( dir2 .. "/atestRequireVersionsNew_Multiple_Version.lua", "w" )
		file2:write([[
			return "barrrf"
		]])
		file2:close()
		
		local mo = bootstrap.requireVersionsNew( require, {"Zefiros-Software", "*"}, ">0.1.0" )
		
		-- test
		u.assertEquals( mo, "barrrf" )
		
		os.rmdir( bootstrap._dirModules )
		
		u.assertFalse( os.isdir( bootstrap._dirModules ) ) 
		bootstrap._dirModules = dirMods
	
		-- path correctly restored
		u.assertEquals( package.path, oldPath )
	
    end
	
	function TestBootstrap:testRequireVersionsNew_Multiple_Same()

		local oldPath = package.path

		-- init
		local dirMods = bootstrap._dirModules
		bootstrap._dirModules = "./modules-test"
		
		local dir = bootstrap._dirModules .. "/Zefiros-Software/testRequireVersionsNew_Multiple_Same/0.0.1"
		local dir2 = bootstrap._dirModules .. "/Zefiros-Software/testRequireVersionsNew_Multiple_Same/0.1.1-alpha"
		
		assert( os.mkdir( dir ) )
		u.assertTrue( os.isdir( dir ) )
		
		assert( os.mkdir( dir2 ) )
		u.assertTrue( os.isdir( dir2 ) )	
					
		local file = io.open( dir .. "/testRequireVersionsNew_Multiple_Same.lua", "w" )
		file:write([[
			return "barrr"
		]])
		file:close()	
			
		local file2 = io.open( dir2 .. "/testRequireVersionsNew_Multiple_Same.lua", "w" )
		file2:write([[
			return "barrrf"
		]])
		file2:close()
		
		local mo = bootstrap.requireVersionsNew( require, {"Zefiros-Software", "*"} )
		
		-- test
		u.assertEquals( mo, "barrrf" )
		
		os.rmdir( bootstrap._dirModules )
		
		u.assertFalse( os.isdir( bootstrap._dirModules ) ) 
		bootstrap._dirModules = dirMods
	
		-- path correctly restored
		u.assertEquals( package.path, oldPath )
	
    end
	
	function TestBootstrap:testRequireVersionsNew_Multiple_Same2()

		local oldPath = package.path

		-- init
		local dirMods = bootstrap._dirModules
		bootstrap._dirModules = "./modules-test"
		
		local dir = bootstrap._dirModules .. "/Zefiros-Software/testRequireVersionsNew_Multiple_Same2/0.0.1"
		local dir2 = bootstrap._dirModules .. "/Zefiros-Software/testRequireVersionsNew_Multiple_Same2/0.1.1-alpha"
		
		assert( os.mkdir( dir ) )
		u.assertTrue( os.isdir( dir ) )
		
		assert( os.mkdir( dir2 ) )
		u.assertTrue( os.isdir( dir2 ) )	
			
		local file2 = io.open( dir2 .. "/testRequireVersionsNew_Multiple_Same2.lua", "w" )
		file2:write([[
			return "barrrrrrf"
		]])
		file2:close()
					
		local file = io.open( dir .. "/testRequireVersionsNew_Multiple_Same2.lua", "w" )
		file:write([[
			return "barrr"
		]])
		file:close()	
		
		local mo = bootstrap.requireVersionsNew( require, {"Zefiros-Software", "*"} )
		
		-- test
		u.assertEquals( mo, "barrrrrrf" )
		
		os.rmdir( bootstrap._dirModules )
		
		u.assertFalse( os.isdir( bootstrap._dirModules ) ) 
		bootstrap._dirModules = dirMods
	
		-- path correctly restored
		u.assertEquals( package.path, oldPath )
	
    end
	
	function TestBootstrap:testRequireVersionsNew_Multiple_Same_Version()

		local oldPath = package.path

		-- init
		local dirMods = bootstrap._dirModules
		bootstrap._dirModules = "./modules-test"
		
		local dir = bootstrap._dirModules .. "/Zefiros-Software/testRequireVersionsNew_Multiple_Same_Version/0.0.1"
		local dir2 = bootstrap._dirModules .. "/Zefiros-Software/testRequireVersionsNew_Multiple_Same_Version/0.1.1-alpha"
		
		assert( os.mkdir( dir ) )
		u.assertTrue( os.isdir( dir ) )
		
		assert( os.mkdir( dir2 ) )
		u.assertTrue( os.isdir( dir2 ) )	
					
		local file = io.open( dir .. "/testRequireVersionsNew_Multiple_Same_Version.lua", "w" )
		file:write([[
			return "barrr"
		]])
		file:close()	
			
		local file2 = io.open( dir2 .. "/testRequireVersionsNew_Multiple_Same_Version.lua", "w" )
		file2:write([[
			return "barrrf"
		]])
		file2:close()
		
		local mo = bootstrap.requireVersionsNew( require, {"Zefiros-Software", "*"}, "^0.1.0" )
		
		-- test
		u.assertEquals( mo, "barrrf" )
		
		os.rmdir( bootstrap._dirModules )
		
		u.assertFalse( os.isdir( bootstrap._dirModules ) ) 
		bootstrap._dirModules = dirMods
	
		-- path correctly restored
		u.assertEquals( package.path, oldPath )
	
    end
	
	function TestBootstrap:testRequireVersionsNew_Multiple_Same_Filter()

		local oldPath = package.path

		-- init
		local dirMods = bootstrap._dirModules
		bootstrap._dirModules = "./modules-test"
		
		local dir = bootstrap._dirModules .. "/Zefiros-Software/versionsNew_Multiple_Same_Filter/0.0.1"
		local dir2 = bootstrap._dirModules .. "/Zefiros-Software/versionsNew_Multiple_Same_Filter/0.1.1-alpha"
		
		assert( os.mkdir( dir ) )
		u.assertTrue( os.isdir( dir ) )
		
		assert( os.mkdir( dir2 ) )
		u.assertTrue( os.isdir( dir2 ) )	
					
		local file = io.open( dir .. "/versionsNew_Multiple_Same_Filter.lua", "w" )
		file:write([[
			return "barrr"
		]])
		file:close()	
			
		local file2 = io.open( dir2 .. "/versionsNew_Multiple_Same_Filter.lua", "w" )
		file2:write([[
			return "barrrf"
		]])
		file2:close()
		
		local mo = bootstrap.requireVersionsNew( require, {"Zefiros-Software", "*"} )
		
		-- test
		u.assertEquals( mo, "barrrf" )
		
		os.rmdir( bootstrap._dirModules )
		
		u.assertFalse( os.isdir( bootstrap._dirModules ) ) 
		bootstrap._dirModules = dirMods
	
		-- path correctly restored
		u.assertEquals( package.path, oldPath )
	
    end
	
	function TestBootstrap:testRequireVersionsNew_Multiple_Filter_Same2()

		local oldPath = package.path

		-- init
		local dirMods = bootstrap._dirModules
		bootstrap._dirModules = "./modules-test"
		
		local dir = bootstrap._dirModules .. "/Zefiros-Software/testRequireVersionsNew_Multiple_Filter_Same2/0.0.1"
		local dir2 = bootstrap._dirModules .. "/Zefiros-Software/testRequireVersionsNew_Multiple_Filter_Same2/0.1.1-alpha"
		
		assert( os.mkdir( dir ) )
		u.assertTrue( os.isdir( dir ) )
		
		assert( os.mkdir( dir2 ) )
		u.assertTrue( os.isdir( dir2 ) )	
			
		local file2 = io.open( dir2 .. "/testRequireVersionsNew_Multiple_Filter_Same2.lua", "w" )
		file2:write([[
			return "barrrf"
		]])
		file2:close()
					
		local file = io.open( dir .. "/testRequireVersionsNew_Multiple_Filter_Same2.lua", "w" )
		file:write([[
			return "barrr"
		]])
		file:close()	
		
		local mo = bootstrap.requireVersionsNew( require, {"Zefiros-Software", "testRequireVersionsNew_Multiple_Filter_Same2"} )
		
		-- test
		u.assertEquals( mo, "barrrf" )
		
		os.rmdir( bootstrap._dirModules )
		
		u.assertFalse( os.isdir( bootstrap._dirModules ) ) 
		bootstrap._dirModules = dirMods
	
		-- path correctly restored
		u.assertEquals( package.path, oldPath )
	
    end
	
	function TestBootstrap:testRequireVersionsNew_Multiple_Same_Filter_Version()

		local oldPath = package.path

		-- init
		local dirMods = bootstrap._dirModules
		bootstrap._dirModules = "./modules-test"
		
		local dir = bootstrap._dirModules .. "/Zefiros-Software/testRequireVersionsNew_Multiple_Same_Filter_Version/0.0.1"
		local dir2 = bootstrap._dirModules .. "/Zefiros-Software/testRequireVersionsNew_Multiple_Same_Filter_Version/1.1.1-alpha"
		
		assert( os.mkdir( dir ) )
		u.assertTrue( os.isdir( dir ) )
		
		assert( os.mkdir( dir2 ) )
		u.assertTrue( os.isdir( dir2 ) )	
					
		local file = io.open( dir .. "/testRequireVersionsNew_Multiple_Same_Filter_Version.lua", "w" )
		file:write([[
			return "barrrf"
		]])
		file:close()	
			
		local file2 = io.open( dir2 .. "/testRequireVersionsNew_Multiple_Same_Filter_Version.lua", "w" )
		file2:write([[
			return "barrr"
		]])
		file2:close()
		
		local mo = bootstrap.requireVersionsNew( require, {"Zefiros-Software", "*"}, ">0.1" )
		
		-- test
		u.assertEquals( mo, "barrr" )
		
		os.rmdir( bootstrap._dirModules )
		
		u.assertFalse( os.isdir( bootstrap._dirModules ) ) 
		bootstrap._dirModules = dirMods
	
		-- path correctly restored
		u.assertEquals( package.path, oldPath )
	
    end
	
	function TestBootstrap:testRequireVersionsNew_NoValidVersion()

		local oldPath = package.path

		-- init
		local dirMods = bootstrap._dirModules
		bootstrap._dirModules = "./modules-test"
		
		local dir = bootstrap._dirModules .. "/Zefiros-Software/testRequireVersionsNew_NoValidVersion/0.0.1"
		local dir2 = bootstrap._dirModules .. "/Zefiros-Software/testRequireVersionsNew_NoValidVersion/1.1.1-alpha"
		
		assert( os.mkdir( dir ) )
		u.assertTrue( os.isdir( dir ) )
		
		assert( os.mkdir( dir2 ) )
		u.assertTrue( os.isdir( dir2 ) )	
					
		local file = io.open( dir .. "/testRequireVersionsNew_NoValidVersion.lua", "w" )
		file:write([[
			return "barrrf"
		]])
		file:close()	
			
		local file2 = io.open( dir2 .. "/testRequireVersionsNew_NoValidVersion.lua", "w" )
		file2:write([[
			return "barrr"
		]])
		file2:close()
		
		u.assertErrorMsgContains( "Module with vendor 'Zefiros-Software' and name '*' has no releases satisfying version '>2'!", bootstrap.requireVersionsNew, require, {"Zefiros-Software", "*"}, ">2" )
		
		
        os.rmdir( bootstrap._dirModules )
		
		u.assertFalse( os.isdir( bootstrap._dirModules ) ) 
		bootstrap._dirModules = dirMods
	
		-- path correctly restored
		u.assertEquals( package.path, oldPath )
	
    end
	
	function TestBootstrap:testRequireVersionsNew_Remember()

		local oldPath = package.path

		-- init
		local dirMods = bootstrap._dirModules
		bootstrap._dirModules = "./modules-test"
		
		local dir = bootstrap._dirModules .. "/Zefiros-Software/testRequireVersionsNew/0.0.1"
		
		assert( os.mkdir( dir ) )
		u.assertTrue( os.isdir( dir ) )
		u.assertFalse( os.isfile( dir .. "/testRequireVersionsNew.lua" ) )
		
		u.assertErrorMsgContains( "Module with vendor 'Zefiros-Software' and name 'testRequireVersionsNew' not found", bootstrap.requireVersionsNew, require, {"Zefiros-Software", "testRequireVersionsNew"} )
				
        os.rmdir( bootstrap._dirModules )
		
		u.assertFalse( os.isdir( bootstrap._dirModules ) ) 
		bootstrap._dirModules = dirMods
	
		-- path correctly restored
		u.assertEquals( package.path, oldPath )
	
    end
	
	function TestBootstrap:testRequireVersionsNew_Remember2()

		local oldPath = package.path

		-- init
		local dirMods = bootstrap._dirModules
		bootstrap._dirModules = "./modules-test"
		
		local dir = bootstrap._dirModules .. "/Zefiros-Software/testRequireVersionsNew/0.0.1"
		
		assert( os.mkdir( dir ) )
		u.assertTrue( os.isdir( dir ) )
			
		local file = io.open( dir .. "/testRequireVersionsNew.lua", "w" )
		file:write([[
			return "fee"
		]])
		file:close()
		
		local mod = bootstrap.requireVersionsNew( require, {"Zefiros-Software", "testRequireVersionsNew"} )
				
		-- test
		u.assertEquals( mo, nil )
		
        os.rmdir( bootstrap._dirModules )
		
		u.assertFalse( os.isdir( bootstrap._dirModules ) ) 
		bootstrap._dirModules = dirMods
	
		-- path correctly restored
		u.assertEquals( package.path, oldPath )
	
    end
			
    function TestBootstrap:testRequireVersionsNew_LuaRockStyle()

		local oldPath = package.path
		
		-- init
		local dirMods = bootstrap._dirModules
		bootstrap._dirModules = "./modules-test"
		
		local dir = bootstrap._dirModules .. "/Zefiros-Software/testRequireVersionsNew_LuaRockStyle/0.0.5"
			
		assert( os.mkdir( dir ) )
		u.assertTrue( os.isdir( dir ) )
			
		local file = io.open( dir .. "/testRequireVersionsNew_LuaRockStyle.lua", "w" )
		file:write([[
			return require( "testRequireVersionsNew_LuaRockStyle.bar" )
		]])
		file:close()
		
			
		file2 = io.open( dir .. "/testRequireVersionsNew_LuaRockStyle/bar.lua", "w" )
		file2:write([[
			return require( "testRequireVersionsNew_LuaRockStyle.bar2" )
		]])
		file2:close()
		
			
		file3 = io.open( dir .. "/testRequireVersionsNew_LuaRockStyle/bar2.lua", "w" )
		file3:write([[
			return "barsss2"
		]])
		file3:close()
		
		local mo = bootstrap.requireVersionsNew( require, {"Zefiros-Software", "testRequireVersionsNew_LuaRockStyle"} )
		
		-- test
		u.assertEquals( mo, "barsss2" )
		
		os.rmdir( bootstrap._dirModules )
		
		u.assertFalse( os.isdir( bootstrap._dirModules ) ) 
		bootstrap._dirModules = dirMods
	
		-- path correctly restored
		u.assertEquals( package.path, oldPath )
	
    end
			
    function TestBootstrap:testRequireVersionsNew_LuaRockStyle_Absolute()

		local oldPath = package.path
		
		-- init
		local dirMods = bootstrap._dirModules
		bootstrap._dirModules = path.join( os.getcwd(), "modules-test" )
		
		local dir = bootstrap._dirModules .. "/Zefiros-Software/testRequireVersionsNew_LuaRockStyle/0.0.5"
			
		assert( os.mkdir( dir ) )
		u.assertTrue( os.isdir( dir ) )
			
		local file = io.open( dir .. "/testRequireVersionsNew_LuaRockStyle.lua", "w" )
		file:write([[
			return require( "testRequireVersionsNew_LuaRockStyle.bar" )
		]])
		file:close()
		
			
		file2 = io.open( dir .. "/testRequireVersionsNew_LuaRockStyle/bar.lua", "w" )
		file2:write([[
			return require( "testRequireVersionsNew_LuaRockStyle.bar2" )
		]])
		file2:close()
		
			
		file3 = io.open( dir .. "/testRequireVersionsNew_LuaRockStyle/bar2.lua", "w" )
		file3:write([[
			return "barsss2"
		]])
		file3:close()
		
		local mo = bootstrap.requireVersionsNew( require, {"Zefiros-Software", "testRequireVersionsNew_LuaRockStyle"} )
		
		-- test
		u.assertEquals( mo, "barsss2" )
		
		os.rmdir( bootstrap._dirModules )
		
		u.assertFalse( os.isdir( bootstrap._dirModules ) ) 
		bootstrap._dirModules = dirMods
	
		-- path correctly restored
		u.assertEquals( package.path, oldPath )
	
    end
	
	
    function TestBootstrap:testRequireVersionsNew_Head()

		local oldPath = package.path
		-- init
		local dirMods = bootstrap._dirModules
		bootstrap._dirModules = "./modules-test"
		
		local dir = bootstrap._dirModules .. "/Zefiros-Software/testRequireVersionsNew_Head/head"
		
		assert( os.mkdir( dir ) )
		u.assertTrue( os.isdir( dir ) )
		
			
		local file = io.open( dir .. "/testRequireVersionsNew_Head.lua", "w" )
		file:write([[
			return "baree"
		]])
		file:close()
		
		local mo = bootstrap.requireVersionsNew( require, {"Zefiros-Software", "testRequireVersionsNew_Head"} )
		
		-- test
		u.assertEquals( mo, "baree" )
		
		os.rmdir( bootstrap._dirModules )
		
		u.assertFalse( os.isdir( bootstrap._dirModules ) ) 
		bootstrap._dirModules = dirMods
	
	
		-- path correctly restored
		u.assertEquals( package.path, oldPath )
    end	
	
	
    function TestBootstrap:testRequireVersionsNew_NoFile()

		local oldPath = package.path
		
		-- init
		local dirMods = bootstrap._dirModules
		bootstrap._dirModules = "./modules-test"
		
		local dir = bootstrap._dirModules .. "/Zefiros-Software/testRequireVersionsNew_NoFile/0.2.0"
		
		assert( os.mkdir( dir ) )
		u.assertTrue( os.isdir( dir ) )
		u.assertFalse( os.isfile( dir .. "/testRequireVersionsNew_NoFile.lua" ) )
		u.assertFalse( os.isfile( dir .. "../head/testRequireVersionsNew_NoFile.lua" ) )
		
		u.assertErrorMsgContains( "Module with vendor 'Zefiros-Software' and name 'testRequireVersionHead_NoFile' not found", bootstrap.requireVersionHead, require, {"Zefiros-Software", "testRequireVersionHead_NoFile"} )
				
		os.rmdir( bootstrap._dirModules )
		
		u.assertFalse( os.isdir( bootstrap._dirModules ) ) 
		bootstrap._dirModules = dirMods
	
		-- path correctly restored
		u.assertEquals( package.path, oldPath )
	
    end	
	
	function TestBootstrap:testRequireVersionsNew_Fail()

		local oldPath = package.path

		-- init
		local dirMods = bootstrap._dirModules
		bootstrap._dirModules = "./modules-test"
		
		local dir = bootstrap._dirModules .. "/Zefiros-Software/testRequireVersionsNew_Fail/0.0.1"
		
		assert( os.mkdir( dir ) )
		u.assertTrue( os.isdir( dir ) )
		
			
		local file = io.open( dir .. "/testRequireVersionsNew_Fail.lua", "w" )
		file:write([[
			return "bar
		]])
		file:close()
		
		u.assertErrorMsgContains( "unfinished string near '\"bar'", bootstrap.requireVersionsNew, require, {"Zefiros-Software", "testRequireVersionsNew_Fail"} )
		
		os.rmdir( bootstrap._dirModules )
		
		u.assertFalse( os.isdir( bootstrap._dirModules ) ) 
		bootstrap._dirModules = dirMods
	
		-- path correctly restored
		u.assertEquals( package.path, oldPath )
	
    end
	
	function TestBootstrap:testRequireVersionsNew_Fail_Head()

		local oldPath = package.path

		-- init
		local dirMods = bootstrap._dirModules
		bootstrap._dirModules = "./modules-test"
		
		local dir = bootstrap._dirModules .. "/Zefiros-Software/testRequireVersionsNew_Fail_Head/head"
		
		assert( os.mkdir( dir ) )
		u.assertTrue( os.isdir( dir ) )
		
			
		local file = io.open( dir .. "/testRequireVersionsNew_Fail_Head.lua", "w" )
		file:write([[
			return "bar
		]])
		file:close()
		
		u.assertErrorMsgContains( "unfinished string near '\"bar'", bootstrap.requireVersionsNew, require, {"Zefiros-Software", "testRequireVersionsNew_Fail_Head"} )
		
		os.rmdir( bootstrap._dirModules )
		
		u.assertFalse( os.isdir( bootstrap._dirModules ) ) 
		bootstrap._dirModules = dirMods
	
		-- path correctly restored
		u.assertEquals( package.path, oldPath )
	
    end
	
	
	
	
    function TestBootstrap:testRequireVersions()

		local oldPath = package.path
		-- init
		local dirMods = bootstrap._dirModules
		bootstrap._dirModules = "./modules-test"
			
		assert( os.mkdir( bootstrap._dirModules ) )
		u.assertTrue( os.isdir( bootstrap._dirModules ) )
		
			
		local file = io.open( bootstrap._dirModules .. "/testRequireVersions.lua", "w" )
		file:write([[
			return "testRequireVersions"
		]])
		file:close()
		
		local mo = bootstrap.requireVersions( require, bootstrap._dirModules .. "/testRequireVersions" )
		
		-- test
		u.assertEquals( mo, "testRequireVersions" )
		
		os.rmdir( bootstrap._dirModules )
		
		u.assertFalse( os.isdir( bootstrap._dirModules ) ) 
		bootstrap._dirModules = dirMods
	
		-- path correctly restored
		u.assertEquals( package.path, oldPath )
    end
	
	function TestBootstrap:testRequireVersions_Head()

		local oldPath = package.path
		-- init
		local dirMods = bootstrap._dirModules
		bootstrap._dirModules = "./modules-test"
		
		local dir = bootstrap._dirModules .. "/Zefiros-Software/testRequireVersions_Head/head"
		
		assert( os.mkdir( dir ) )
		u.assertTrue( os.isdir( dir ) )		
			
		local file = io.open( dir .. "/testRequireVersions_Head.lua", "w" )
		file:write([[
			return "testRequireVersions_Head"
		]])
		file:close()
		
		local mo, found = bootstrap.requireVersions( require, "Zefiros-Software/testRequireVersions_Head", "@head" )
		
		-- test
		u.assertEquals( mo, "testRequireVersions_Head" )
		u.assertTrue( found )
		
		os.rmdir( bootstrap._dirModules )
		
		u.assertFalse( os.isdir( bootstrap._dirModules ) ) 
		bootstrap._dirModules = dirMods
	
	
		-- path correctly restored
		u.assertEquals( package.path, oldPath )
    end	
	
	function TestBootstrap:testRequireVersions_Head_Fallback()

		local oldPath = package.path
		-- init
		local dirMods = bootstrap._dirModules
		bootstrap._dirModules = "./modules-test"
		
		local dir = bootstrap._dirModules .. "/Zefiros-Software/testRequireVersions_Head_Fallback/head"
		
		assert( os.mkdir( dir ) )
		u.assertTrue( os.isdir( dir ) )
		
			
		local file = io.open( dir .. "/testRequireVersions_Head_Fallback.lua", "w" )
		file:write([[
			return "bar"
		]])
		file:close()
		
		local mo = bootstrap.requireVersions( require, "Zefiros-Software/testRequireVersions_Head_Fallback" )
		
		-- test
		u.assertEquals( mo, "bar" )
		
		os.rmdir( bootstrap._dirModules )
		
		u.assertFalse( os.isdir( bootstrap._dirModules ) ) 
		bootstrap._dirModules = dirMods
	
	
		-- path correctly restored
		u.assertEquals( package.path, oldPath )
    end
	
	function TestBootstrap:testRequireVersions_Version()

		local oldPath = package.path
		-- init
		local dirMods = bootstrap._dirModules
		bootstrap._dirModules = "./modules-test"
		
		local dir = bootstrap._dirModules .. "/Zefiros-Software/testRequireVersions_Version/0.2.3"
		
		assert( os.mkdir( dir ) )
		u.assertTrue( os.isdir( dir ) )
		
			
		local file = io.open( dir .. "/testRequireVersions_Version.lua", "w" )
		file:write([[
			return "bar"
		]])
		file:close()
		
		local mo = bootstrap.requireVersions( require, "Zefiros-Software/testRequireVersions_Version" )
		
		-- test
		u.assertEquals( mo, "bar" )
		
		os.rmdir( bootstrap._dirModules )
		
		u.assertFalse( os.isdir( bootstrap._dirModules ) ) 
		bootstrap._dirModules = dirMods
	
	
		-- path correctly restored
		u.assertEquals( package.path, oldPath )
    end	
	
	function TestBootstrap:testRequireVersions_Version()

		local oldPath = package.path
		-- init
		local dirMods = bootstrap._dirModules
		bootstrap._dirModules = "./modules-test"
		
		local dir = bootstrap._dirModules .. "/Zefiros-Software/testRequireVersions_Version/0.2.3"
		
		assert( os.mkdir( dir ) )
		u.assertTrue( os.isdir( dir ) )
		
			
		local file = io.open( dir .. "/testRequireVersions_Version.lua", "w" )
		file:write([[
			return "bar"
		]])
		file:close()
		
		local mo = bootstrap.requireVersions( require, "Zefiros-Software/testRequireVersions_Version" )
		
		-- test
		u.assertEquals( mo, "bar" )
		
		os.rmdir( bootstrap._dirModules )
		
		u.assertFalse( os.isdir( bootstrap._dirModules ) ) 
		bootstrap._dirModules = dirMods
	
	
		-- path correctly restored
		u.assertEquals( package.path, oldPath )
    end	
	
	
	
	function TestBootstrap:testzRequireVersionsFromDirectories()

		local dirs = bootstrap.directories
		bootstrap.directories = { "a", "b", "c" }
		local requireVersions = bootstrap.requireVersions
		local its = 0
		bootstrap.requireVersions = function()
			its = its + 1
			
			if its == 1 then
				u.assertEquals( bootstrap._dirModules, "a" )
				error( "next" )
			
				return "fault"
			elseif its == 2 then
				u.assertEquals( bootstrap._dirModules, "b" )
				error( "next" )
			
				return "fault"
			elseif its == 3 then
				u.assertEquals( bootstrap._dirModules, "c" )
			
				return "correct"
			else
			 	assert( false, "This should not happen!" )
			end
			
			return "brrrr"
		end
		
		local mod = bootstrap.requireVersionsFromDirectories( nil, "testzRequireVersionsFromDirectories", nil )
		
		u.assertEquals( mod, "correct" )	
		u.assertEquals( its, 3 )	
		
		bootstrap.requireVersions = requireVersions
		bootstrap.directories = dirs
    end	
		
	function TestBootstrap:testzRequireVersionsFromDirectories_2()

		local dirs = bootstrap.directories
		bootstrap.directories = { "a", "b", "c" }
		local requireVersions = bootstrap.requireVersions
		local its = 0
		bootstrap.requireVersions = function()
			its = its + 1
			
			if its == 1 then
				u.assertEquals( bootstrap._dirModules, "a" )
				error( "next" )
			
				return "fault"
			elseif its == 2 then
				u.assertEquals( bootstrap._dirModules, "b" )
			
				return "correct"
			elseif its == 3 then
				u.assertEquals( bootstrap._dirModules, "c" )			
				error( "next" )
				
				return "fault"
			else
			 	assert( false, "This should not happen!" )
			end
			
			return "brrrr"
		end
		
		local mod = bootstrap.requireVersionsFromDirectories( nil, "testzRequireVersionsFromDirectories_2", nil )
		
		u.assertEquals( mod, "correct" )	
		u.assertEquals( its, 2 )	
		
		bootstrap.requireVersions = requireVersions
		bootstrap.directories = dirs
    end	
		
	function TestBootstrap:testzRequireVersionsFromDirectories_3()

		local dirs = bootstrap.directories
		bootstrap.directories = { "a", "b", "c" }
		local requireVersions = bootstrap.requireVersions
		local its = 0
		bootstrap.requireVersions = function()
			its = its + 1
			
			if its == 1 then
				u.assertEquals( bootstrap._dirModules, "a" )
				error( "next" )
			
				return "fault"
			elseif its == 2 then
				u.assertEquals( bootstrap._dirModules, "b" )
				error( "next" )
			
				return "fault"
			elseif its == 3 then
				u.assertEquals( bootstrap._dirModules, "c" )	
				
				return "correct"
			else
			 	assert( false, "This should not happen!" )
			end
			
			return "brrrr"
		end
		
		local mod = bootstrap.requireVersionsFromDirectories( nil, "testzRequireVersionsFromDirectories_3", nil )
		
		u.assertEquals( mod, "correct" )	
		u.assertEquals( its, 3 )	
		
		bootstrap.requireVersions = requireVersions
		bootstrap.directories = dirs
    end
		
	function TestBootstrap:testzRequireVersionsFromDirectories_None()

		local dirs = bootstrap.directories
		bootstrap.directories = { "a", "b", "c" }
		local requireVersions = bootstrap.requireVersions
		local its = 0
		bootstrap.requireVersions = function()
			its = its + 1
			
			if its == 1 then
				u.assertEquals( bootstrap._dirModules, "a" )
				error( "next1" )
			
				return "fault"
			elseif its == 2 then
				u.assertEquals( bootstrap._dirModules, "b" )
				error( "next2" )
			
				return "fault"
			elseif its == 3 then
				u.assertEquals( bootstrap._dirModules, "c" )	
				error( "next3" )
				
				return "fault"
			end
			
			return "brrrr"
		end
		
		u.assertErrorMsgContains( "next3", bootstrap.requireVersionsFromDirectories, nil, "testzRequireVersionsFromDirectories_3", nil )

		u.assertEquals( its, 3 )	
		
		bootstrap.requireVersions = requireVersions
		bootstrap.directories = dirs
    end	
	
	
	
	function TestBootstrap:testRequire()

		local requireVersions = bootstrap.requireVersions
		local its = 0
		bootstrap.requireVersions = function()
			its = its + 1
			return "brrrr"
		end
		
		local mod = bootstrap.require( nil, "testRequire", nil )
		
		u.assertEquals( mod, "brrrr" )	
		u.assertEquals( its, 1 )	
		
		bootstrap.requireVersions = requireVersions
    end	
	
	
	
	function TestBootstrap:testRequire_Dirs()

		local requireVersionsFromDirectories = bootstrap.requireVersionsFromDirectories
		local its = 0
		bootstrap.requireVersionsFromDirectories = function()
			its = its + 1
			return "brrrr"
		end
		
		local mod = bootstrap.require( nil, "requireVersionsFromDirectories_Dirs", nil )
		
		u.assertEquals( mod, "brrrr" )	
		u.assertEquals( its, 1 )	
		
		bootstrap.requireVersionsFromDirectories = requireVersionsFromDirectories
    end	
	
	function TestBootstrap:testRequire_Memoisation()

		local requireVersions = bootstrap.requireVersions
		local its = 0
		bootstrap.requireVersions = function()
			its = its + 1
			return "brrrr"
		end
		
		local mod = bootstrap.require( nil, "testRequire_Memoisation", nil )
		
		u.assertEquals( mod, "brrrr" )	
		u.assertEquals( its, 1 )	
		
		mod = bootstrap.require( nil, "testRequire_Memoisation", nil )
		u.assertEquals( mod, "brrrr" )	
		u.assertEquals( its, 1 )
		
		bootstrap.requireVersions = requireVersions
    end	
	
	function TestBootstrap:testRequire_onLoad()

		local requireVersions = bootstrap.requireVersions
		local its = 0
		local loaded = 0
		bootstrap.requireVersions = function()
			its = its + 1
			local ret = {}
			function ret:onLoad()
				loaded = loaded + 1
			end
			ret.value = "brrrr"
			
			return ret
		end
		
		local mod = bootstrap.require( nil, "testRequire_onLoad", nil )
		
		u.assertEquals( mod.value, "brrrr" )	
		u.assertEquals( its, 1 )	
		u.assertEquals( loaded, 1 )
		
		mod = bootstrap.require( nil, "testRequire_onLoad", nil )
		u.assertEquals( mod.value, "brrrr" )	
		u.assertEquals( its, 1 )
		u.assertEquals( loaded, 1 )
		
		bootstrap.requireVersions = requireVersions
    end	