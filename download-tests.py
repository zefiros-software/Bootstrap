import github3
import zipfile
import platform
import tarfile
from shutil import move
import os

repo = github3.repository( "premake", "premake-core")

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

            move("bin/premake5", "bin/" + asset.name.replace(".zip", "") )
            
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

            move("bin/premake5", "bin/" + asset.name.replace(".zip", "") )