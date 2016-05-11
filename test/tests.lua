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
        u.assertIsString( bootstrap.dirModules )
    end
	
    function TestBootstrap:testOnLoad_CorrectInit()
	
		local i = bootstrap.init
		
		local dir = ""
		
		bootstrap.init = function( directory )
			dir = directory
		end
		
		bootstrap.onLoad()
		
	 	u.assertEquals( dir, bootstrap.dirModules )
		
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
		local dirMods = bootstrap.dirModules
		bootstrap.dirModules = "modules-test"
		
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
		bootstrap.dirModules = dirMods
	
    end
	
    function TestBootstrap:testListModulesTags_Init()

		-- init
		local dirMods = bootstrap.dirModules
		bootstrap.dirModules = "modules-test"
		
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
			
			file = io.open( dir .. "/init.lua", "w" )
			file:close()
		end
		
		-- test
		
		local tags = bootstrap.listModulesTags()
		u.assertEquals( #tags, 9 )
		u.assertItemsEquals( tags, {			
			{
				path = "modules-test/Zefiros-Softwarefe/df/3.4.0",
				version = "3.4.0"
			},
			{
				path = "modules-test/Zefiros-Softwarefe/df/1.5.4-ga", 
				version = "1.5.4-ga"
			},
			{
				path = "modules-test/Zefiros-Softwarefe/df/0.3.1", 
				version = "0.3.1"
			},
			{
				path = "modules-test/Zefiros-Software/zpm2/2.0.0",
				version = "2.0.0"
			},
			{
				path = "modules-test/Zefiros-Software/zpm2/1.0.0-beta", 
				version = "1.0.0-beta"
			},
			{
				path = "modules-test/Zefiros-Software/zpm2/0.0.1", 
				version = "0.0.1"
			},
			{
				path = "modules-test/Zefiros-Software/zpm/3.0.0",
				version = "3.0.0"
			},
			{
				path = "modules-test/Zefiros-Software/zpm/1.0.0-alpha",
				version = "1.0.0-alpha"
			},
			{
				path = "modules-test/Zefiros-Software/zpm/0.0.1",
				version = "0.0.1"
			}
		} ) 
		
		-- cleanup
		os.rmdir( "modules-test" )
		
		u.assertFalse( os.isdir( "modules-test" ) ) 
		bootstrap.dirModules = dirMods
	
    end
	
    function TestBootstrap:testListModulesTags_InitModule()

		-- init
		local dirMods = bootstrap.dirModules
		bootstrap.dirModules = "modules-test"
		
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
			
			assert( os.mkdir( dir ) )
			u.assertTrue( os.isdir( dir ) )
			
			file = io.open( dir .. "/zpm.lua", "w" )
			file:close()
		end
		
		-- test
		local tags = bootstrap.listModulesTags()
		u.assertEquals( #tags, 9 )
		u.assertItemsEquals( tags, {			
			{
				path = "modules-test/Zefiros-Softwarefe/zpm/3.4.0",
				version = "3.4.0"
			},
			{
				path = "modules-test/Zefiros-Softwarefe/zpm/1.5.4-ga", 
				version = "1.5.4-ga"
			},
			{
				path = "modules-test/Zefiros-Softwarefe/zpm/0.3.1", 
				version = "0.3.1"
			},
			{
				path = "modules-test/Zefiros-Software/zpm/3.0.0",
				version = "3.0.0"
			},
			{
				path = "modules-test/Zefiros-Software/zpm/2.0.0",
				version = "2.0.0"
			},
			{
				path = "modules-test/Zefiros-Software/zpm/1.0.0-beta", 
				version = "1.0.0-beta"
			},
			{
				path = "modules-test/Zefiros-Software/zpm/1.0.0-alpha",
				version = "1.0.0-alpha"
			},
			{
				path = "modules-test/Zefiros-Software/zpm/0.0.2", 
				version = "0.0.2"
			},
			{
				path = "modules-test/Zefiros-Software/zpm/0.0.1",
				version = "0.0.1"
			}
		} ) 
		
		-- cleanup
		os.rmdir( "modules-test" )
		
		u.assertFalse( os.isdir( "modules-test" ) ) 
		bootstrap.dirModules = dirMods
	
    end
	
    function TestBootstrap:testListModulesTags_HeadIgnored()

		-- init
		local dirMods = bootstrap.dirModules
		bootstrap.dirModules = "modules-test"
		
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
			
			assert( os.mkdir( dir ) )
			u.assertTrue( os.isdir( dir ) )
			
			file = io.open( dir .. "/init.lua", "w" )
			file:close()
		end
		
		-- test
		
		local tags = bootstrap.listModulesTags()
		u.assertEquals( #tags, 9 )
		u.assertItemsEquals( tags, {			
			{
				path = "modules-test/Zefiros-Softwarefe/df/3.4.0",
				version = "3.4.0"
			},
			{
				path = "modules-test/Zefiros-Softwarefe/df/1.5.4-ga", 
				version = "1.5.4-ga"
			},
			{
				path = "modules-test/Zefiros-Softwarefe/df/0.3.1", 
				version = "0.3.1"
			},
			{
				path = "modules-test/Zefiros-Software/zpm2/2.0.0",
				version = "2.0.0"
			},
			{
				path = "modules-test/Zefiros-Software/zpm2/1.0.0-beta", 
				version = "1.0.0-beta"
			},
			{
				path = "modules-test/Zefiros-Software/zpm2/0.0.1", 
				version = "0.0.1"
			},
			{
				path = "modules-test/Zefiros-Software/zpm/3.0.0",
				version = "3.0.0"
			},
			{
				path = "modules-test/Zefiros-Software/zpm/1.0.0-alpha",
				version = "1.0.0-alpha"
			},
			{
				path = "modules-test/Zefiros-Software/zpm/0.0.1",
				version = "0.0.1"
			}
		} ) 
		
		-- cleanup
		os.rmdir( "modules-test" )
		
		u.assertFalse( os.isdir( "modules-test" ) ) 
		bootstrap.dirModules = dirMods
	
    end
	
    function TestBootstrap:testListModulesTags_Mixed()

		-- init
		local dirMods = bootstrap.dirModules
		bootstrap.dirModules = "modules-test"
		
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
			
			assert( os.mkdir( dir ) )
			u.assertTrue( os.isdir( dir ) )
			
			if i ~= 1 then
				file = io.open( dir .. "/init.lua", "w" )
				file:close()
			end
		end
		
		-- test
		
		local tags = bootstrap.listModulesTags()
		u.assertEquals( #tags, 9 )
		u.assertItemsEquals( tags, {			
			{
				path = "modules-test/Zefiros-Softwarefe/df/3.4.0",
				version = "3.4.0"
			},
			{
				path = "modules-test/Zefiros-Softwarefe/df/1.5.4-ga", 
				version = "1.5.4-ga"
			},
			{
				path = "modules-test/Zefiros-Softwarefe/df/0.3.1", 
				version = "0.3.1"
			},
			{
				path = "modules-test/Zefiros-Software/zpm2/2.0.0",
				version = "2.0.0"
			},
			{
				path = "modules-test/Zefiros-Software/zpm2/1.0.0-beta", 
				version = "1.0.0-beta"
			},
			{
				path = "modules-test/Zefiros-Software/zpm2/0.0.1", 
				version = "0.0.1"
			},
			{
				path = "modules-test/Zefiros-Software/zpm/3.0.0",
				version = "3.0.0"
			},
			{
				path = "modules-test/Zefiros-Software/zpm/1.0.0-alpha",
				version = "1.0.0-alpha"
			},
			{
				path = "modules-test/Zefiros-Software/zpm/0.0.1",
				version = "0.0.1"
			}
		} ) 
		
		-- cleanup
		os.rmdir( "modules-test" )
		
		u.assertFalse( os.isdir( "modules-test" ) ) 
		bootstrap.dirModules = dirMods
	
    end
	
    function TestBootstrap:testListModulesTags_MatchVendor()

		-- init
		local dirMods = bootstrap.dirModules
		bootstrap.dirModules = "modules-test"
		
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
			
			assert( os.mkdir( dir ) )
			u.assertTrue( os.isdir( dir ) )
			
			file = io.open( dir .. "/init.lua", "w" )
			file:close()
		end
		
		-- test
		
		local tags = bootstrap.listModulesTags( "Zefiros_Softwarefe" )
		u.assertEquals( #tags, 3 )
		u.assertItemsEquals( tags, {			
			{
				path = "modules-test/Zefiros_Softwarefe/df/3.4.0",
				version = "3.4.0"
			},
			{
				path = "modules-test/Zefiros_Softwarefe/df/1.5.4-ga", 
				version = "1.5.4-ga"
			},
			{
				path = "modules-test/Zefiros_Softwarefe/df/0.3.1", 
				version = "0.3.1"
			}
		} ) 
		
		-- cleanup
		os.rmdir( "modules-test" )
		
		u.assertFalse( os.isdir( "modules-test" ) ) 
		bootstrap.dirModules = dirMods
	
    end
	
    function TestBootstrap:testListModulesTags_MatchModule()

		-- init
		local dirMods = bootstrap.dirModules
		bootstrap.dirModules = "modules-test"
		
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
			
			assert( os.mkdir( dir ) )
			u.assertTrue( os.isdir( dir ) )
			
			file = io.open( dir .. "/init.lua", "w" )
			file:close()
		end
		
		-- test
		
		local tags = bootstrap.listModulesTags( "*", "zpm" )
		u.assertEquals( #tags, 3 )
		u.assertItemsEquals( tags, {	
			{
				path = "modules-test/Zefiros-Software/zpm/3.0.0",
				version = "3.0.0"
			},
			{
				path = "modules-test/Zefiros-Software/zpm/1.0.0-alpha",
				version = "1.0.0-alpha"
			},
			{
				path = "modules-test/Zefiros-Software/zpm/0.0.1",
				version = "0.0.1"
			}
		} ) 
		
		-- cleanup
		os.rmdir( "modules-test" )
		
		u.assertFalse( os.isdir( "modules-test" ) ) 
		bootstrap.dirModules = dirMods
	
    end
		
	
    function TestBootstrap:testListModulesHead_NoInit()

		-- init
		local dirMods = bootstrap.dirModules
		bootstrap.dirModules = "modules-test"
		
		local dirs = { 
			"modules-test/Zefiros-Software/zpm/head",	
			"modules-test/Zefiros-Software/zpm2/head",	
			"modules-test/Zefiros-Softwarefe/df/head" 
		}
		
		for _, dir in ipairs( dirs ) do
			
			assert( os.mkdir( dir ) )
			u.assertTrue( os.isdir( dir ) )
		end
		
		-- test
		
		local tags = bootstrap.listModulesHead()
		u.assertEquals( #tags, 0 )
		os.rmdir( "modules-test" )
		
		u.assertFalse( os.isdir( "modules-test" ) ) 
		bootstrap.dirModules = dirMods
	
    end	
	
    function TestBootstrap:testListModulesHead_Init()

		-- init
		local dirMods = bootstrap.dirModules
		bootstrap.dirModules = "modules-test"
		
		local dirs = { 
			"modules-test/Zefiros-Software/zpm/head",	
			"modules-test/Zefiros-Software/zpm2/head",	
			"modules-test/Zefiros-Softwarefe/df/head" 
		}
		
		for _, dir in ipairs( dirs ) do
			
			assert( os.mkdir( dir ) )
			u.assertTrue( os.isdir( dir ) )
			
			file = io.open( dir .. "/init.lua", "w" )
			file:close()
		end
		
		-- test
		
		local tags = bootstrap.listModulesHead()
		u.assertEquals( #tags, 3 )
		u.assertItemsEquals( tags, {
			"modules-test/Zefiros-Software/zpm/head",
			"modules-test/Zefiros-Software/zpm2/head",
			"modules-test/Zefiros-Softwarefe/df/head"
		} ) 
		os.rmdir( "modules-test" )
		
		u.assertFalse( os.isdir( "modules-test" ) ) 
		bootstrap.dirModules = dirMods
	
    end
	
    function TestBootstrap:testListModulesHead_InitModule()

		-- init
		local dirMods = bootstrap.dirModules
		bootstrap.dirModules = "modules-test"
		
		local dirs = { 
			"modules-test/Zefiros-Software/zpm/head",	
			"modules-test/Zefiros/zpm/head",	
			"modules-test/Zefiros-Softwarefe/zpm/head" 
		}
		
		for _, dir in ipairs( dirs ) do
			
			assert( os.mkdir( dir ) )
			u.assertTrue( os.isdir( dir ) )
			
			file = io.open( dir .. "/zpm.lua", "w" )
			file:close()
		end
		
		-- test
		
		local tags = bootstrap.listModulesHead()
		u.assertEquals( #tags, 3 )
		u.assertItemsEquals( tags, {
			"modules-test/Zefiros-Software/zpm/head",
			"modules-test/Zefiros/zpm/head",
			"modules-test/Zefiros-Softwarefe/zpm/head"
		} ) 
		os.rmdir( "modules-test" )
		
		u.assertFalse( os.isdir( "modules-test" ) ) 
		bootstrap.dirModules = dirMods
	
    end
	
    function TestBootstrap:testListModulesHead_VersionIgnored()

		-- init
		local dirMods = bootstrap.dirModules
		bootstrap.dirModules = "modules-test"
		
		local dirs = { 
			"modules-test/Zefiros-Software/zpm/head",	
			"modules-test/Zefiros/zpm/head",	
			"modules-test/Zefiros-Softwarefe/zpm/head",	
			"modules-test/Zefiros-Softwareffe/zpm/0.0.1" 
		}
		
		for _, dir in ipairs( dirs ) do
			
			assert( os.mkdir( dir ) )
			u.assertTrue( os.isdir( dir ) )
			
			file = io.open( dir .. "/zpm.lua", "w" )
			file:close()
		end
		
		-- test
		
		local tags = bootstrap.listModulesHead()
		u.assertEquals( #tags, 3 )
		u.assertItemsEquals( tags, {
			"modules-test/Zefiros-Software/zpm/head",
			"modules-test/Zefiros/zpm/head",
			"modules-test/Zefiros-Softwarefe/zpm/head"
		} ) 
		os.rmdir( "modules-test" )
		
		u.assertFalse( os.isdir( "modules-test" ) ) 
		bootstrap.dirModules = dirMods
	
    end
	
    function TestBootstrap:testListModulesHead_MatchVendor()

		-- init
		local dirMods = bootstrap.dirModules
		bootstrap.dirModules = "modules-test"
		
		local dirs = { 
			"modules-test/Zefiros-Software/zpm/head",	
			"modules-test/Zefiros/zpm/head",	
			"modules-test/Zefiros_Softwarefe/zpm/head"
		}
		
		for _, dir in ipairs( dirs ) do
			
			assert( os.mkdir( dir ) )
			u.assertTrue( os.isdir( dir ) )
			
			file = io.open( dir .. "/zpm.lua", "w" )
			file:close()
		end
		
		-- test
		
		local tags = bootstrap.listModulesHead()
		u.assertEquals( #tags, 3 )
		u.assertItemsEquals( tags, {
			"modules-test/Zefiros-Software/zpm/head",
			"modules-test/Zefiros/zpm/head",
			"modules-test/Zefiros_Softwarefe/zpm/head"
		} ) 
		os.rmdir( "modules-test" )
		
		u.assertFalse( os.isdir( "modules-test" ) ) 
		bootstrap.dirModules = dirMods
	
    end
	
    function TestBootstrap:testCheckVersion_Basic()
	
		u.assertTrue( bootstrap.checkVersion( premake.checkVersion, "0.5.0", ">0.4.0" ) )
		u.assertFalse( bootstrap.checkVersion( premake.checkVersion, "0.5.0", ">0.5.0" ) )
	
    end
	
    function TestBootstrap:testCheckVersion_Multiple()
		
		u.assertTrue( bootstrap.checkVersion( premake.checkVersion, "0.5.0", "<=0.0.0 || >0.4.0" ) )
		u.assertFalse( bootstrap.checkVersion( premake.checkVersion, "0.5.0", "<=0.0.0 || >0.5.0" ) )
	
    end
	
    function TestBootstrap:testCheckVersion_Trim()

		u.assertTrue( bootstrap.checkVersion( premake.checkVersion, "0.5.0", "<=0.0.0  ||   >0.4.0" ) )
		u.assertFalse( bootstrap.checkVersion( premake.checkVersion, "0.5.0", "<=0.0.0  ||   >0.5.0" ) )
	
    end
	
    function TestBootstrap:testCheckVersion_Tripple()

		u.assertTrue( bootstrap.checkVersion( premake.checkVersion, "0.5.0", "<=0.0.0  ||>1.0.0  ||   >0.4.0" ) )
		u.assertFalse( bootstrap.checkVersion( premake.checkVersion, "0.5.0", "<=0.0.0  ||>1.0.0  ||   >0.5.0" ) )
	
    end
	
    function TestBootstrap:testRequireOld()

		-- init
		local dirMods = bootstrap.dirModules
		bootstrap.dirModules = "modules-test"
			
		assert( os.mkdir( bootstrap.dirModules ) )
		u.assertTrue( os.isdir( bootstrap.dirModules ) )
		
			
		file = io.open( bootstrap.dirModules .. "/foo.lua", "w" )
		file:write([[
			return "bar"
		]])
		file:close()
		
		local mo = bootstrap.requireVersionsOld( require, bootstrap.dirModules .. "/foo" )
		
		-- test
		u.assertEquals( mo, "bar" )
		
		os.rmdir( bootstrap.dirModules )
		
		u.assertFalse( os.isdir( bootstrap.dirModules ) ) 
		bootstrap.dirModules = dirMods
	
    end
	
    function TestBootstrap:testRequireOld_Remember()

		-- init
		local dirMods = bootstrap.dirModules
		bootstrap.dirModules = "modules-test"
			
		assert( os.mkdir( bootstrap.dirModules ) )
		u.assertTrue( os.isdir( bootstrap.dirModules ) )
		u.assertFalse( os.isdir( bootstrap.dirModules .. "/foo.lua" ) )
		
		local mo = bootstrap.requireVersionsOld( require, bootstrap.dirModules .. "/foo" )
		
		-- test
		u.assertEquals( mo, "bar" )
		
		os.rmdir( bootstrap.dirModules )
		
		u.assertFalse( os.isdir( bootstrap.dirModules ) ) 
		bootstrap.dirModules = dirMods
	
    end
	
    function TestBootstrap:testRequireOld_LuaRockStyle()

		-- init
		local dirMods = bootstrap.dirModules
		bootstrap.dirModules = "modules-test"
			
		assert( os.mkdir( bootstrap.dirModules ) )
		u.assertTrue( os.isdir( bootstrap.dirModules ) )
			
		file = io.open( bootstrap.dirModules .. "/foos.lua", "w" )
		file:write([[
			return require( "foos.bar" )
		]])
		file:close()
		
			
		file2 = io.open( bootstrap.dirModules .. "/foos/bar.lua", "w" )
		file2:write([[
			return require( "foos.bar2" )
		]])
		file2:close()
		
			
		file3 = io.open( bootstrap.dirModules .. "/foos/bar2.lua", "w" )
		file3:write([[
			return "bar2"
		]])
		file3:close()
		
		local mo = bootstrap.requireVersionsOld( require, bootstrap.dirModules .. "/foos" )
		
		-- test
		u.assertEquals( mo, "bar2" )
		
		os.rmdir( bootstrap.dirModules )
		
		u.assertFalse( os.isdir( bootstrap.dirModules ) ) 
		bootstrap.dirModules = dirMods
	
    end
	
    function TestBootstrap:testRequireOld_NoFile()

		-- init
		local dirMods = bootstrap.dirModules
		bootstrap.dirModules = "modules-test"
		u.assertFalse( os.isdir( bootstrap.dirModules .. "/foo3.lua" ) )
			
		assert( os.mkdir( bootstrap.dirModules ) )
		u.assertTrue( os.isdir( bootstrap.dirModules ) )
		
		u.assertErrorMsgContains( "module 'modules-test/foo3' not found", bootstrap.requireVersionsOld, require, bootstrap.dirModules .. "/foo3" )
		
		os.rmdir( bootstrap.dirModules )
		
		u.assertFalse( os.isdir( bootstrap.dirModules ) ) 
		bootstrap.dirModules = dirMods
	
    end
	
    function TestBootstrap:testRequireOld_Fail()

		-- init
		local dirMods = bootstrap.dirModules
		bootstrap.dirModules = "modules-test"
			
		assert( os.mkdir( bootstrap.dirModules ) )
		u.assertTrue( os.isdir( bootstrap.dirModules ) )
		
			
		file = io.open( bootstrap.dirModules .. "/foo4.lua", "w" )
		file:write([[
			return "barf
		]])
		file:close()
		
		u.assertErrorMsgContains( "unfinished string near '\"barf'", bootstrap.requireVersionsOld, require, bootstrap.dirModules .. "/foo4" )
		
		os.rmdir( bootstrap.dirModules )
		
		u.assertFalse( os.isdir( bootstrap.dirModules ) ) 
		bootstrap.dirModules = dirMods
	
    end
	
	
	
	
	
	
    function TestBootstrap:testRequireVersionHead()

		-- init
		local dirMods = bootstrap.dirModules
		bootstrap.dirModules = "modules-test"
		
		local dir = bootstrap.dirModules .. "/Zefiros-Software/zpm/head"
		
		assert( os.mkdir( dir ) )
		u.assertTrue( os.isdir( dir ) )
		
			
		file = io.open( dir .. "/zpm.lua", "w" )
		file:write([[
			return "bar"
		]])
		file:close()
		
		local mo = bootstrap.requireVersionHead( require, {"Zefiros-Software", "zpm"} )
		
		-- test
		u.assertEquals( mo, "bar" )
		
		os.rmdir( bootstrap.dirModules )
		
		u.assertFalse( os.isdir( bootstrap.dirModules ) ) 
		bootstrap.dirModules = dirMods
	
    end
	
	function TestBootstrap:testRequireVersionHead_CWD()

		-- init
		local dirMods = bootstrap.dirModules
		
		local dir = "Zefiros-Software/zpm/head"
		
		assert( os.mkdir( dir ) )
		u.assertTrue( os.isdir( dir ) )
					
		file = io.open( dir .. "/zpm.lua", "w" )
		file:write([[
			return "bar"
		]])
		file:close()
		
		local mo = bootstrap.requireVersionHead( require, {"Zefiros-Software", "zpm"} )
		
		-- test
		u.assertEquals( mo, "bar" )
		
		os.rmdir( "Zefiros-Software" )
		
		u.assertFalse( os.isdir( dir ) )
	
    end
	
	function TestBootstrap:testRequireVersionHead_Multiple()

		-- init
		local dirMods = bootstrap.dirModules
		
		local dir = "Zefiros-Software/zpm/head"
		local dir2 = "Zefiros-Software/zpm2/head"
		
		assert( os.mkdir( dir ) )
		u.assertTrue( os.isdir( dir ) )
		
		assert( os.mkdir( dir2 ) )
		u.assertTrue( os.isdir( dir2 ) )
					
		file = io.open( dir .. "/zpm.lua", "w" )
		file:write([[
			return "bar"
		]])
		file:close()
					
		file2 = io.open( dir2 .. "/zpm2.lua", "w" )
		file2:write([[
			return "bar2"
		]])
		file2:close()
		
		local mo = bootstrap.requireVersionHead( require, {"Zefiros-Software", "*"} )
		
		-- test
		u.assertEquals( mo, "bar" )
		
		os.rmdir( dir )
		
		u.assertFalse( os.isdir( dir ) )
	
    end
	
	function TestBootstrap:testRequireVersionHead_Multiple2()

		-- init
		local dirMods = bootstrap.dirModules
		
		local dir = "Zefiros-Software/zpm/head"
		local dir2 = "Zefiros-Software/zpm2/head"
		
		assert( os.mkdir( dir2 ) )
		u.assertTrue( os.isdir( dir2 ) )
		
		assert( os.mkdir( dir ) )
		u.assertTrue( os.isdir( dir ) )
					
		file2 = io.open( dir2 .. "/zpm2.lua", "w" )
		file2:write([[
			return "bar2"
		]])
		file2:close()
					
		file = io.open( dir .. "/zpm.lua", "w" )
		file:write([[
			return "bar"
		]])
		file:close()
		
		local mo = bootstrap.requireVersionHead( require, {"Zefiros-Software", "*"} )
		
		-- test
		u.assertEquals( mo, "bar" )
		
		os.rmdir( dir )
		
		u.assertFalse( os.isdir( dir ) )
	
    end
	
    function TestBootstrap:testRequireVersionHead_Remember()

		-- init
		local dirMods = bootstrap.dirModules
		bootstrap.dirModules = "modules-test"
		
		local dir = bootstrap.dirModules .. "/Zefiros-Software/zpm/head"
		
		assert( os.mkdir( dir ) )
		u.assertTrue( os.isdir( dir ) )
		u.assertFalse( os.isdir( dir .. "/zpm.lua" ) )
		
		u.assertErrorMsgContains( "Module with vendor 'Zefiros-Software' and name 'zpm' not found!", bootstrap.requireVersionHead, require, {"Zefiros-Software", "zpm"} )
				
		os.rmdir( bootstrap.dirModules )
		
		u.assertFalse( os.isdir( bootstrap.dirModules ) ) 
		bootstrap.dirModules = dirMods
	
    end