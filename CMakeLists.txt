cmake_minimum_required(VERSION 3.5)
project(Lua VERSION 5.2.4 LANGUAGES C)

if(NOT EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/src/luaconf.h")
  message(FATAL_ERROR "Run \"cmake -P prepare-sources.cmake\" and change dirs.")
endif()

# Lua headers and source files.
set(LUA_TO_INC lua.h luaconf.h lualib.h lauxlib.h lua.hpp)
#file(GLOB LUA_SOURCES src/l*.c)
#list(REMOVE_ITEM LUA_SOURCES lua.c luac.c)
# Copied CORE_O and LIB_O from src/Makefile, with .o -> .c
set(LUA_CORE_SOURCES lapi.c lcode.c lctype.c ldebug.c ldo.c ldump.c lfunc.c
  lgc.c llex.c lmem.c lobject.c lopcodes.c lparser.c lstate.c lstring.c ltable.c
  ltm.c lundump.c lvm.c lzio.c)
set(LUA_LIB_SOURCES lauxlib.c lbaselib.c lbitlib.c lcorolib.c ldblib.c liolib.c
  lmathlib.c loslib.c lstrlib.c ltablib.c loadlib.c linit.c)
set(LUA_SOURCES)
foreach(_src IN LISTS LUA_CORE_SOURCES LUA_LIB_SOURCES)
  list(APPEND LUA_SOURCES "src/${_src}")
endforeach()
set(LUA_HEADERS)
foreach(_hdr IN LISTS LUA_TO_INC)
  list(APPEND LUA_HEADERS "src/${_hdr}")
endforeach()
# Extra sources.
list(APPEND LUA_SOURCES src/utf8_wrappers.c)

add_definitions(-DUA_COMPAT_ALL)
if(WIN32)
  add_definitions(-DLUA_BUILD_AS_DLL
    -DWIN32_LEAN_AND_MEAN -D_CRT_SECURE_NO_DEPRECATE)
elseif(APPLE)
  add_definitions(-DLUA_USE_MACOSX)
elseif(CMAKE_SYSTEM_NAME STREQUAL "Linux")
  add_definitions(-DLUA_USE_LINUX)
elseif(UNIX)
  add_definitions(-DLUA_USE_POSIX)
else()
  message(WARNING "Unknown target, the library might lack features.")
endif()
if(MSVC)
  # /Zo Enhance Optimized Debugging (since MSVC 2013).
  add_compile_options(/Zo)
endif()
if(WIN32)
  set(OUTPUT_NAME_SUFFIX ${PROJECT_VERSION_MAJOR}${PROJECT_VERSION_MINOR})
else()
  set(OUTPUT_NAME_SUFFIX ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR})
endif()


# Build objects used by the shared library and executables.
add_library(lua_objects OBJECT ${LUA_SOURCES})
set_property(TARGET lua_objects PROPERTY POSITION_INDEPENDENT_CODE ON)

# Build shared library.
add_library(lua_shared SHARED $<TARGET_OBJECTS:lua_objects>)
set_target_properties(lua_shared PROPERTIES
  OUTPUT_NAME lua${OUTPUT_NAME_SUFFIX})
if(UNIX)
  target_link_libraries(lua_shared m ${CMAKE_DL_LIBS})
endif()

# Build executables.
add_executable(lua_binary src/lua.c src/utf8_wmain.c)
set_target_properties(lua_binary PROPERTIES
  PDB_NAME lua${OUTPUT_NAME_SUFFIX}.exe
  OUTPUT_NAME lua${OUTPUT_NAME_SUFFIX})
if(APPLE OR CMAKE_SYSTEM_NAME STREQUAL "Linux")
  target_link_libraries(lua_binary readline)
endif()
# Link dynamically to ensure a shared VM when loading C libraries.
target_link_libraries(lua_binary lua_shared)

add_executable(luac_binary src/luac.c src/utf8_wmain.c
  $<TARGET_OBJECTS:lua_objects>)
set_target_properties(luac_binary PROPERTIES
  OUTPUT_NAME luac${OUTPUT_NAME_SUFFIX})
if(UNIX)
  target_link_libraries(luac_binary m ${CMAKE_DL_LIBS})
endif()

if(WIN32 AND MSVC)
  # LUA_BUILD_AS_DLL results in LNK4217 warnings while linking the executables
  # since these statically link with objects that export symbols which are
  # locally used by the executables. Ignore to avoid recompiling.
  set_target_properties(luac_binary PROPERTIES
    LINK_FLAGS "/ignore:4217")
endif()


install(FILES ${LUA_HEADERS} DESTINATION include)
if(WIN32)
  install(TARGETS lua_shared lua_binary luac_binary DESTINATION .)
  install(FILES $<TARGET_PDB_FILE:lua_shared>
    CONFIGURATIONS Debug RelWithDebInfo DESTINATION .)

  # Add build files for documentation purposes.
  install(FILES CMakeLists.txt build-all.ps1 prepare-sources.cmake README.md
    DESTINATION .)
  install(FILES src/utf8_wrappers.c src/utf8_wrappers.h src/utf8_wmain.c
    DESTINATION src)
else()
  install(TARGETS lua_shared LIBRARY DESTINATION lib)
  install(TARGETS lua_binary luac_binary RUNTIME DESTINATION bin)
endif()

if(WIN32)
  if(CMAKE_GENERATOR_PLATFORM STREQUAL "Win32")
    set(name lua-${PROJECT_VERSION}-unicode-win32)
  elseif(CMAKE_GENERATOR_PLATFORM STREQUAL "x64")
    set(name lua-${PROJECT_VERSION}-unicode-win64)
  else()
    message(FATAL_ERROR "Unexpected generator platform")
  endif()
  if(MSVC_TOOLCHAIN_VERSION)
    math(EXPR msvc_major "${MSVC_TOOLSET_VERSION} / 10")
    set(name "${name}-vc${msvc_major}")
  endif()
  set(CMAKE_INSTALL_PREFIX ${name})
  add_custom_command(OUTPUT ${name}.zip
    COMMAND "${CMAKE_COMMAND}" -E remove_directory "${name}"
    COMMAND "${CMAKE_COMMAND}" --build . --target install --config $<CONFIG>
    COMMAND "${CMAKE_COMMAND}" -E tar cf "${name}.zip" --format=zip "${name}"
    VERBATIM)
  add_custom_target(create-zip DEPENDS ${name}.zip)
  message(STATUS "Ready to build ${name}")
endif()
