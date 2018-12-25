# Downloads, verifies and unpacks a patched source tree into ${TARBALL_DIR}.
# (A subdirectory will be created for the sources.)

cmake_minimum_required(VERSION 3.5)
set(PROJECT_VERSION 5.2.4)

set(URL https://www.lua.org/ftp/lua-${PROJECT_VERSION}.tar.gz)
set(SHA256 b9e2e4aad6789b3b63a056d442f7b39f0ecfca3ae0f1fc0ae4e9614401b69f4b)

# Destination settings.
if(NOT TARBALL_DIR)
  # Directory to store the source tarball and create the source directory.
  set(TARBALL_DIR .)
endif()

# Retrieve tarball if missing
get_filename_component(TARBALL ${TARBALL_DIR}/lua-${PROJECT_VERSION}.tar.gz ABSOLUTE)
if(NOT EXISTS ${TARBALL})
  message(STATUS "Downloading ${URL}")
  file(DOWNLOAD ${URL} ${TARBALL} EXPECTED_HASH SHA256=${SHA256})
else()
  file(SHA256 ${TARBALL} _hash)
  if(NOT _hash STREQUAL SHA256)
    message(FATAL_ERROR "Hash mismatch for ${TARBALL}
      Expected hash: ${SHA256}
        Actual hash: ${_hash}")
  endif()
endif()

# Unpack sources.
get_filename_component(LUA_SRCDIR ${TARBALL_DIR}/lua-${PROJECT_VERSION} ABSOLUTE)
if(NOT EXISTS ${LUA_SRCDIR})
  get_filename_component(lua_srcdir_parent "${LUA_SRCDIR}" DIRECTORY)
  file(MAKE_DIRECTORY ${LUA_SRCDIR})
  execute_process(COMMAND "${CMAKE_COMMAND}" -E tar xzf "${TARBALL}"
    WORKING_DIRECTORY "${lua_srcdir_parent}"
    RESULT_VARIABLE unpack_result)
  if(NOT unpack_result EQUAL 0)
    message(FATAL_ERROR "Failed to unpack ${TARBALL}")
  endif()
endif()

# Patch the header to include our UTF-8 wrappers for Windows.
file(READ "${LUA_SRCDIR}/src/luaconf.h" luaconf_h)
if(NOT luaconf_h MATCHES ".*utf8_wrappers.h.*")
  set(conditionals "defined(LUA_LIB) || defined(lua_c) || defined(luac_c)")
  string(REGEX REPLACE
    "(Local configuration\\.[^\n]+\n(\\*[^\n]+\n)+)"
    "\\1#if ${conditionals}\n#include \"utf8_wrappers.h\"\n#endif\n"
    patched_luaconf_h "${luaconf_h}")
  if(luaconf_h STREQUAL patched_luaconf_h)
    message(FATAL_ERROR "Failed to patch luaconf.h")
  endif()
  file(WRITE "${LUA_SRCDIR}/src/luaconf.h" "${patched_luaconf_h}")
  message(STATUS "Patched luaconf.h")
endif()
file(COPY src/utf8_wrappers.h src/utf8_wrappers.c src/utf8_wmain.c
  DESTINATION "${LUA_SRCDIR}/src")
file(COPY CMakeLists.txt build-all.ps1 prepare-sources.cmake README.md
  DESTINATION "${LUA_SRCDIR}")

message(STATUS "Source tree is ready at ${LUA_SRCDIR}")
