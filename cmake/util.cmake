################################################################################
# Project:  CMake4GDAL
# Purpose:  CMake build scripts
# Author:   Mikhail Gusev, gusevmihs@gmail.com
# Author:   Dmitry Baryshnikov, dmitry.baryshnikov@nextgis.com
################################################################################
# Copyright (C) 2016-2019, NextGIS <info@nextgis.com>
# Copyright (C) 2016, Mikhail Gusev
# Copyright (c) 2018-2019, Dmitry Baryshnikov
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
# OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
# DEALINGS IN THE SOFTWARE.
################################################################################

function(check_version major minor release build)
    set(filename "${CMAKE_SOURCE_DIR}/src/interfaces/libpq/libpq.rc.in")
    file(READ ${filename} FILE_CONTENTS)
    string(REGEX MATCH "FILEVERSION[ \t]+[0-9]+,[0-9]+,[0-9]+,[0-9]+" VERSION_STR ${FILE_CONTENTS})
    string(REGEX MATCHALL "[0-9]+" VERSIONS_LIST ${VERSION_STR})
    list(GET VERSIONS_LIST 0 VER_MAJOR)
    list(GET VERSIONS_LIST 2 VER_MINOR)
    list(GET VERSIONS_LIST 3 VER_RELEASE)
    # list(GET VERSIONS_LIST 2 VER_BUILD)
    set(${major} ${VER_MAJOR} PARENT_SCOPE)
    set(${minor} ${VER_MINOR} PARENT_SCOPE)
    set(${release} ${VER_RELEASE} PARENT_SCOPE)
    # set(${build} ${VER_BUILD} PARENT_SCOPE)

    # Store version string in file for installer needs
    file(TIMESTAMP ${filename} VERSION_DATETIME "%Y-%m-%d %H:%M:%S" UTC)
    set(VERSION ${VER_MAJOR}.${VER_MINOR}.${VER_RELEASE})
    get_cpack_filename(${VERSION} PROJECT_CPACK_FILENAME)
    file(WRITE ${CMAKE_BINARY_DIR}/version.str "${VERSION}\n${VERSION_DATETIME}\n${PROJECT_CPACK_FILENAME}")
endfunction()

function(report_version name ver)
    string(ASCII 27 Esc)
    set(BoldYellow  "${Esc}[1;33m")
    set(ColourReset "${Esc}[m")
    message("${BoldYellow}${name} version ${ver}${ColourReset}")
endfunction()

# macro to find programs on the host OS
macro( find_exthost_program )
    if(CMAKE_CROSSCOMPILING)
        set( CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER )
        set( CMAKE_FIND_ROOT_PATH_MODE_LIBRARY NEVER )
        set( CMAKE_FIND_ROOT_PATH_MODE_INCLUDE NEVER )

        find_program( ${ARGN} )

        set( CMAKE_FIND_ROOT_PATH_MODE_PROGRAM ONLY )
        set( CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY )
        set( CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY )
    else()
        find_program( ${ARGN} )
    endif()
endmacro()


function(get_prefix prefix IS_STATIC)
  if(IS_STATIC)
    set(STATIC_PREFIX "static-")
      if(ANDROID)
        set(STATIC_PREFIX "${STATIC_PREFIX}android-${ANDROID_ABI}-")
      elseif(IOS)
        set(STATIC_PREFIX "${STATIC_PREFIX}ios-${IOS_ARCH}-")
      endif()
    endif()
  set(${prefix} ${STATIC_PREFIX} PARENT_SCOPE)
endfunction()


function(get_cpack_filename ver name)
    get_compiler_version(COMPILER)
    
    if(NOT DEFINED BUILD_STATIC_LIBS)
      set(BUILD_STATIC_LIBS OFF)
    endif()

    get_prefix(STATIC_PREFIX ${BUILD_STATIC_LIBS})

    set(${name} ${PROJECT_NAME}-${ver}-${STATIC_PREFIX}${COMPILER} PARENT_SCOPE)
endfunction()

function(get_compiler_version ver)
    ## Limit compiler version to 2 or 1 digits
    string(REPLACE "." ";" VERSION_LIST ${CMAKE_C_COMPILER_VERSION})
    list(LENGTH VERSION_LIST VERSION_LIST_LEN)
    if(VERSION_LIST_LEN GREATER 2 OR VERSION_LIST_LEN EQUAL 2)
        list(GET VERSION_LIST 0 COMPILER_VERSION_MAJOR)
        list(GET VERSION_LIST 1 COMPILER_VERSION_MINOR)
        set(COMPILER ${CMAKE_C_COMPILER_ID}-${COMPILER_VERSION_MAJOR}.${COMPILER_VERSION_MINOR})
    else()
        set(COMPILER ${CMAKE_C_COMPILER_ID}-${CMAKE_C_COMPILER_VERSION})
    endif()

    if(WIN32)
        if(CMAKE_CL_64)
            set(COMPILER "${COMPILER}-64bit")
        endif()
    endif()

    set(${ver} ${COMPILER} PARENT_SCOPE)
endfunction()
