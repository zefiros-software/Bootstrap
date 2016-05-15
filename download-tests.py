import github3
import zipfile
import platform
from shutil import move
import os

gh = github3.login(token="6b3b4ef8d2746bf694214dd20ac0f6dbad684afb")
repo = gh.repository( "premake", "premake-core")

ignoreReleases = [ "Premake 5.0 alpha 4", "Premake 5.0 alpha 5" ]


for release in reversed(list(repo.releases())):

    # remove the ignored releases
    if any(release.name in s for s in ignoreReleases):
        continue
        
    print( "Downloading " + release.name )
    
    for asset in release.assets():
        
        if platform.system() == "Linux" and "linux" in asset.name:
        
            asset.download("bin/temp/" + asset.name)
            tar = tarfile.open("bin/temp/" + asset.name, "r:gz")
            tar.extractall( "bin" )
            tar.close()

            move("bin/premake5.exe", "bin/" + asset.name.replace(".zip", ".exe") )
            
        elif platform.system() == "Windows" and "windows" in asset.name:
        
            asset.download("bin/temp/" + asset.name)
            with zipfile.ZipFile("bin/temp/" + asset.name, "r") as z:
                z.extractall("bin")
                move("bin/premake5.exe", "bin/" + asset.name.replace(".zip", ".exe") )
            
        elif platform.system() == "Darwin" and "osx" in asset.name:
        
            asset.download("bin/temp/" + asset.name)
            tar = tarfile.open("bin/temp/" + asset.name, "r:gz")
            tar.extractall( "bin" )
            tar.close()

            move("bin/premake5.exe", "bin/" + asset.name.replace(".zip", ".exe") )