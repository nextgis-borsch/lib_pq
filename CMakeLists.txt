################################################################################
# Project:  libpq
# Purpose:  CMake build scripts
# Author:   Mikhail Gusev, gusevmihs@gmail.com
# Author:   Dmitry Baryshnikov, dmitry.baryshnikov@nextgis.com
################################################################################
# Copyright (C) 2016,2017, NextGIS <info@nextgis.com>
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

cmake_minimum_required(VERSION 2.8.12 FATAL_ERROR)

project(pq)

# Some init settings
set(CMAKE_COLOR_MAKEFILE ON)
# Set path to additional CMake modules
set(CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake ${CMAKE_MODULE_PATH})

if(OSX_FRAMEWORK AND (BUILD_SHARED_LIBS OR BUILD_STATIC_LIBS))
  message(FATAL_ERROR "Only OSX_FRAMEWORK key or any or both BUILD_SHARED_LIBS
                       and BUILD_STATIC_LIBS keys are permitted")
endif()

if(OSX_FRAMEWORK)
  set(INSTALL_BIN_DIR "${CMAKE_INSTALL_PREFIX}/Applications" CACHE INTERNAL "Installation directory for executables" FORCE)
  set(INSTALL_LIB_DIR "${CMAKE_INSTALL_PREFIX}/Library/Frameworks" CACHE INTERNAL "Installation directory for libraries" FORCE)
  set(INSTALL_INC_DIR ${INSTALL_LIB_DIR}/${PROJECT_NAME}.framework/Headers CACHE INTERNAL "Installation directory for headers" FORCE)
  set(SKIP_INSTALL_HEADERS ON)
  set(SKIP_INSTALL_EXECUTABLES ON)
  set(SKIP_INSTALL_FILES ON)
  set(SKIP_INSTALL_EXPORT ON)
  set(CMAKE_MACOSX_RPATH ON)
else()
    include(GNUInstallDirs)

    set(INSTALL_BIN_DIR ${CMAKE_INSTALL_FULL_BINDIR} CACHE INTERNAL "Installation directory for executables" FORCE)
    set(INSTALL_LIB_DIR ${CMAKE_INSTALL_FULL_LIBDIR} CACHE INTERNAL "Installation directory for libraries" FORCE)
    set(INSTALL_INC_DIR ${CMAKE_INSTALL_FULL_INCLUDEDIR} CACHE INTERNAL "Installation directory for headers" FORCE)
endif()

include(util)
check_version(POSTGRES_MAJOR_VERSION POSTGRES_MINOR_VERSION POSTGRES_PATCH_VERSION VER_H_BUILD)
math(EXPR PG_VERSION_NUM "${POSTGRES_MAJOR_VERSION} * 10000 + ${POSTGRES_MINOR_VERSION} * 100 + ${POSTGRES_PATCH_VERSION}")
set(PG_VERSION "${POSTGRES_MAJOR_VERSION}.${POSTGRES_MINOR_VERSION}.${POSTGRES_PATCH_VERSION}")
set(VERSION "${POSTGRES_MAJOR_VERSION}.${POSTGRES_MINOR_VERSION}.${POSTGRES_PATCH_VERSION}")
report_version(${PROJECT_NAME} ${VERSION})

if(OSX_FRAMEWORK)
    set(FRAMEWORK_VERSION "${POSTGRES_MAJOR_VERSION}")
endif()

### Rename directories:
if(NOT INCLUDEDIR)
	set(INCLUDEDIR "${INSTALL_INC_DIR}")
endif(NOT INCLUDEDIR)
if(NOT PKGINCLUDEDIR)
	set(PKGINCLUDEDIR "${INSTALL_INC_DIR}")
endif(NOT PKGINCLUDEDIR)
if(NOT LIBDIR)
	set(LIBDIR "${INSTALL_LIB_DIR}")
endif(NOT LIBDIR)
if(NOT PKGLIBDIR)
	set(PKGLIBDIR "${INSTALL_LIB_DIR}")
endif(NOT PKGLIBDIR)

### Do all configurations.
include(FindAnyProject)
include(configure)

###find_package(Perl REQUIRED)
###find_package(PerlLibs)
###if(PERLLIBS_FOUND)
###	EXECUTE_PROCESS(COMMAND ${PERL_EXECUTABLE} -MExtUtils::Embed -e ccopts OUTPUT_VARIABLE PERL_CFLAGS)
###	EXECUTE_PROCESS(COMMAND ${PERL_EXECUTABLE} -MExtUtils::Embed -e ldopts OUTPUT_VARIABLE PERL_LDFLAGS)
###	STRING(REGEX REPLACE "[\r\n]" " " PERL_CFLAGS ${PERL_CFLAGS})
###	STRING(REGEX REPLACE " +$" "" PERL_CFLAGS ${PERL_CFLAGS})
###	STRING(STRIP "${PERL_CFLAGS}" PERL_CFLAGS)
###	STRING(REGEX REPLACE "[\r\n]" " " PERL_LDFLAGS ${PERL_LDFLAGS})
###	STRING(REGEX REPLACE " +$" "" PERL_LDFLAGS ${PERL_LDFLAGS})
###	STRING(STRIP "${PERL_LDFLAGS}" PERL_LDFLAGS)
###endif()

###find_package(BISON REQUIRED)
###find_package(FLEX REQUIRED)

find_anyproject(OpenSSL)
###find_package(ZLIB)
###find_package(PythonInterp)
###find_package(PythonLibs)
###find_package(SELinux)
###find_package(LibXml2)
###find_package(LibXslt)
###find_package(TCL)

if(OPENSSL_FOUND)
	set(USE_OPENSSL 1)
    add_definitions(-DUSE_OPENSSL)
    if(WITH_OpenSSL_EXTERNAL)
        add_definitions(-DHAVE_SSL_GET_CURRENT_COMPRESSION -DHAVE_BIO_GET_DATA -DHAVE_OPENSSL_INIT_SSL -DHAVE_BIO_METH_NEW -DHAVE_ASN1_STRING_GET0_DATA) ### for our external system we know it definitely
    else()
        set(CMAKE_REQUIRED_LIBRARIES ${OPENSSL_LIBRARIES})
        set(CMAKE_REQUIRED_INCLUDES ${OPENSSL_INCLUDE_DIR})
        check_function_exists(SSL_get_current_compression HAVE_SSL_GET_CURRENT_COMPRESSION)
        if(HAVE_SSL_GET_CURRENT_COMPRESSION)
            add_definitions(-DHAVE_SSL_GET_CURRENT_COMPRESSION)
        endif()
        check_function_exists(BIO_get_data HAVE_BIO_GET_DATA)
        if(HAVE_BIO_GET_DATA)
            add_definitions(-DHAVE_BIO_GET_DATA)
        endif()
        check_function_exists(OPENSSL_init_ssl HAVE_OPENSSL_INIT_SSL)
        if(HAVE_OPENSSL_INIT_SSL)
            add_definitions(-DHAVE_OPENSSL_INIT_SSL)
        endif()
        check_function_exists(BIO_meth_new HAVE_BIO_METH_NEW)
        if(HAVE_BIO_METH_NEW)
            add_definitions(-DHAVE_BIO_METH_NEW)
        endif()
        check_function_exists(ASN1_STRING_get0_data HAVE_ASN1_STRING_GET0_DATA)
        if(HAVE_ASN1_STRING_GET0_DATA)
            add_definitions(-DHAVE_ASN1_STRING_GET0_DATA)
        endif()
        unset(CMAKE_REQUIRED_LIBRARIES)
        unset(CMAKE_REQUIRED_INCLUDES)
    endif()
###	set(CMAKE_REQUIRED_INCLUDES ${OPENSSL_INCLUDE_DIR})
###	set(CMAKE_REQUIRED_LIBRARIES ${OPENSSL_LIBRARIES})
endif()

###if(LIBXML2_FOUND)
###	set(HAVE_LIBXML2 1)
###	set(USE_LIBXML 1)
###endif()

###if(LIBXSLT_FOUND)
###	set(HAVE_LIBXSLT 1)
###endif()

###if(ZLIB_FOUND)
###	set(HAVE_LIBZ 1)
###endif()

#Check ReadLine includes
###option(WITH_READLINE "do not use GNU Readline nor BSD Libedit for editing" ON)
###if(WITH_READLINE AND NOT MSVC)
###	find_package(Readline)
###	if(READLINE_FOUND)
###		#Sometimes for redline need curses
###		find_package(Curses)
###		if(NOT CURSES_FOUND)
###			set(CURSES_NEED_NCURSES TRUE)
###		endif()
###		find_package(Curses)
###		check_include_files("stdio.h;readline.h" HAVE_READLINE_H)
###		check_include_files("stdio.h;history.h" HAVE_HISTORY_H)
###		check_include_files("stdio.h;readline/history.h" HAVE_READLINE_HISTORY_H)
###		check_include_files("stdio.h;readline/readline.h" HAVE_READLINE_READLINE_H)
###		check_include_files("stdio.h;editline/history.h" HAVE_EDITLINE_HISTORY_H)
###		check_include_files("stdio.h;editline/readline.h" HAVE_EDITLINE_READLINE_H)
###
###
###		set(CMAKE_REQUIRED_LIBRARIES ${CMAKE_REQUIRED_LIBRARIES} ${READLINE_LIBRARY})
###		if(CURSES_FOUND)
###			set(CMAKE_REQUIRED_LIBRARIES ${CMAKE_REQUIRED_LIBRARIES} ${CURSES_LIBRARIES})
###			set(READLINE_LIBRARY ${READLINE_LIBRARY} ${CURSES_LIBRARIES})
###		endif()
###		check_function_exists(rl_completion_matches HAVE_RL_COMPLETION_MATCHES)
###		check_function_exists(rl_filename_completion_function HAVE_RL_FILENAME_COMPLETION_FUNCTION)
###	endif(READLINE_FOUND)
###endif()

### For generated configure files:
include_directories("${PROJECT_BINARY_DIR}/src/include")
include_directories("${PROJECT_SOURCE_DIR}/src/include")
include_directories("${PROJECT_BINARY_DIR}/src/port")


set(PORT_DIR "${PROJECT_SOURCE_DIR}/src/port")
set(PQ_BACKEND_DIR "${PROJECT_SOURCE_DIR}/src/backend/libpq")
set(MB_UTILS_BACKEND_DIR "${PROJECT_SOURCE_DIR}/src/backend/utils/mb")


set(fallback_SRCS "")
if(NOT HAVE_DECL_STRLCPY)
  set(fallback_SRCS ${fallback_SRCS} "${PORT_DIR}/strlcpy.c")
endif()

if(NOT HAVE_DECL_STRLCAT)
  set(fallback_SRCS ${fallback_SRCS} "${PORT_DIR}/strlcat.c")
endif()

if(NOT HAVE_GETPEEREID)
  set(fallback_SRCS ${fallback_SRCS} "${PORT_DIR}/getpeereid.c")
endif()

### The following added so not to use perl for replacing snprintf functions.
### Note: in msvc2013 there is no snprintf() function at all.
if(NOT HAVE_DECL_SNPRINTF)
    add_definitions(-DUSE_REPL_SNPRINTF)
    set(fallback_SRCS ${fallback_SRCS} "${PORT_DIR}/snprintf.c")
endif()

option(HAVE_SPINLOCKS "Define to ON if you have spinlocks." ON)
option(HAVE_ATOMICS "Define to ON if you want to use atomics if available." ON)
option(USE_INTEGER_DATETIMES "Define to ON if you want 64-bit integer timestamp and interval support." ON)

if(WIN32)
	option(HAVE_SYMLINK "Define to ON if you have the `symlink' function." ON)
else()
	set(HAVE_SYMLINK 1)
endif()
option(PG_KRB_SRVNAM "Define to the name of the default PostgreSQL service principal in Kerberos (GSSAPI)." "postgres")

if(WIN32)
	include_directories("${PROJECT_SOURCE_DIR}/src/include/port/win32")
endif()

if(MSVC)
	include_directories("${PROJECT_SOURCE_DIR}/src/include/port/win32_msvc")
endif()


### Define lib name in a common way.
set(LIB_NAME ${PROJECT_NAME})
if(BUILD_SHARED_LIBS)
    set(LIB_TYPE SHARED)
else()
    set(LIB_TYPE STATIC)
endif()

set(EXPORT_TARGETS)

set(PUBLIC_HDRS
    ${PROJECT_SOURCE_DIR}/src/include/postgres_ext.h
    ${PROJECT_BINARY_DIR}/src/include/pg_config.h
	${PROJECT_BINARY_DIR}/src/include/pg_config_ext.h
	${PROJECT_BINARY_DIR}/src/include/pg_config_os.h
)

set(PUBLIC_HDRS_PQ
    ${PROJECT_SOURCE_DIR}/src/include/libpq/libpq-fs.h
)

add_subdirectory(src)
###add_subdirectory(contrib)

### Install other headers.
if(NOT SKIP_INSTALL_HEADERS AND NOT SKIP_INSTALL_ALL)
    # These headers are needed by the public headers of the interfaces.
    install(FILES ${PUBLIC_HDRS}
    ###	src/include/pg_config_manual.h
    	DESTINATION ${CMAKE_INSTALL_INCLUDEDIR})
    install(FILES ${PUBLIC_HDRS_PQ}	DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/libpq)
endif()

### Finally export libpq.
if(EXPORT_TARGETS)
    export(TARGETS ${EXPORT_TARGETS} FILE ${LIB_NAME}-exports.cmake EXPORT_LINK_INTERFACE_LIBRARIES)
endif()

if (REGISTER_PACKAGE)
    export(TARGETS ${EXPORT_TARGETS} FILE ${PROJECT_NAME}-exports.cmake)

    set(EXPORT_PACKAGE_NAME PostgreSQL)
    string(TOUPPER ${EXPORT_PACKAGE_NAME} EXPORT_PACKAGE_NAME_UPPER)
    set(EXPORT_PACKAGE_LIB_NAME ${PROJECT_NAME})

    export(PACKAGE ${EXPORT_PACKAGE_NAME})

    include(CMakePackageConfigHelpers)
    configure_package_config_file(
        ${CMAKE_SOURCE_DIR}/cmake/PackageConfig.cmake.in
        ${CMAKE_CURRENT_BINARY_DIR}/${EXPORT_PACKAGE_NAME}Config.cmake
    INSTALL_DESTINATION ${CMAKE_CURRENT_BINARY_DIR} )
    write_basic_package_version_file(
        ${CMAKE_CURRENT_BINARY_DIR}/${EXPORT_PACKAGE_NAME}ConfigVersion.cmake
        VERSION ${VERSION}
        COMPATIBILITY AnyNewerVersion )
else()
    export(TARGETS ${EXPORT_TARGETS} FILE ${PROJECT_NAME}-exports.cmake EXPORT_LINK_INTERFACE_LIBRARIES)
endif()

add_custom_target(uninstall COMMAND ${CMAKE_COMMAND} -P ${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake)
