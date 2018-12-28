# Lua Unicode for Windows
Patched Lua library to add UTF-8 support on Windows.

[Lua](https://www.lua.org/) is portable due to limiting itself to ANSI C APIs.
Lua does not care about character encoding, its strings are essentially binary
buffers. It is up to applications to interpret it.

Systems like Linux and macOS typically use UTF-8 which has the advantage of
being compatible with 7-bit ASCII. This encoding is also used for filesystem
paths and shell commands.

Windows on the other hand interprets these paths and commands according to a
system-dependent code page (which is typically not UTF-8). For (embedded)
applications that provide UTF-8 encoded strings, this means that some form of
conversion is necessary, like
[winapi.short_path](https://stevedonovan.github.io/winapi/api.html#short_path).
This however complicates Lua code which must now detect Windows and convert
paths before using `dofile`, `io.open` and so on. Additionally it is still not
able to support filenames outside the current code page.

We take a different approach and patch the Lua core to transparently accept
UTF-8 and call appropriate Windows-specific Unicode routines. That way,
applications can always assume UTF-8 support for the following:

- loadfile, dofile and friends.
- io.open
- io.popen, os.execute (note: a cmd.exe window could still pop up in GUI
  applications, fixing that is probably out of scope for this project.)
- os.remove
- os.rename
- package.loadlib (as well as the search path for Lua libraries).

It deliberately does not add newer API interfaces (which would be better suited
for an external library) nor change data types. The resulting binaries are ABI
compatible with those distributed by the LuaBinaries project.

Prebuilt binaries and source zips are available in the releases section of
https://github.com/Lekensteyn/lua-unicode (issues can also be reported here).

## Changes
This project modifies the Lua core in a minimal way and is ABI compatible with
the standard Lua library.

The source tree is created using `cmake -P prepare-sources.cmake` which:

1. Downloads the source tarball and verifies its integrity.
2. Unpacks the source tree.
3. Add `src/utf8_wrappers.h` and  `src/utf8_wrappers.c`.
4. Add `src/utf8_wmain.c` (affects executables only, not the DLL).
5. Patch `src/luaconf.h` to add the following in the *Local configuration* part:

       #if defined(LUA_LIB) || defined(lua_c) || defined(luac_c)
       #include "utf8_wrappers.h"
       #endif

6. Add extra build scripts (CMakeLists.txt) and documentation.

Run `build-all.ps1` in the resulting source tree to create zip archives for both
32-bit and 64-bit binaries consisting of:

- Lua DLL (linked with VCRUNTIME140.dll or whatever compiler you use).
- Header files (in the include directory).
- Lua executables (lua and luac).
- PDB for the Lua DLL (for debugging).
- Build scripts, additional source code and documentation (for reproducibility).

These zip archives will have a subdirectory containing all files (unlike the
LuaBinaries project which puts all files in the top-level directory).

## License
Lua is Copyright © 1994–2018 Lua.org, PUC-Rio. See the sources for details on
the MIT license.

The extra changes from this project (additional sources, build scripts and
documentation files) are

    Copyright (c) 2018 Peter Wu <peter@lekensteyn.nl>
    SPDX-License-Identifier: (GPL-2.0-or-later OR MIT)
