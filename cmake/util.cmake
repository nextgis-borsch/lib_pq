################################################################################
# Project:  CMake4GDAL
# Purpose:  CMake build scripts
# Author:   Mikhail Gusev, gusevmihs@gmail.com
################################################################################
# Copyright (C) 2016, NextGIS <info@nextgis.com>
# Copyright (C) 2016, Mikhail Gusev
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

function(set_pq_version major minor release build)
    set(filename "${CMAKE_SOURCE_DIR}/src/interfaces/libpq/libpq.rc.in")
    file(READ ${filename} FILE_CONTENTS)
    string(REGEX MATCH "FILEVERSION[ \t]+[0-9]+,[0-9]+,[0-9]+,[0-9]+" VERSION_STR ${FILE_CONTENTS})
    string(REGEX MATCHALL "[0-9]+" VERSIONS_LIST ${VERSION_STR})
    list(GET VERSIONS_LIST 0 VER_MAJOR)
    list(GET VERSIONS_LIST 1 VER_MINOR)
    list(GET VERSIONS_LIST 2 VER_RELEASE)
    list(GET VERSIONS_LIST 3 VER_BUILD)
    set(${major} ${VER_MAJOR} PARENT_SCOPE)
    set(${minor} ${VER_MINOR} PARENT_SCOPE)
    set(${release} ${VER_RELEASE} PARENT_SCOPE)
    set(${build} ${VER_BUILD} PARENT_SCOPE)
endfunction()

function(report_version name ver)
    string(ASCII 27 Esc)
    set(BoldYellow  "${Esc}[1;33m")
    set(ColourReset "${Esc}[m")
    message(STATUS "${BoldYellow}${name} version ${ver}${ColourReset}")
endfunction()    

