# Download Lua sources and build binary packages for Win32/Win64.

# Abort whenever a command fails.
$ErrorActionPreference = "Stop"

New-Item -Type Directory build64
Push-Location build64
cmake .. -A x64
cmake --build . --target create-zip --config RelWithDebInfo
Move-Item *.zip ..
Pop-Location

New-Item -Type Directory build32
Push-Location build32
cmake .. -A Win32
cmake --build . --target create-zip --config RelWithDebInfo
Move-Item *.zip ..
Pop-Location
