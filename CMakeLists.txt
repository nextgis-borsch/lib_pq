### CMake Postgres project: only for libpq external library. 

cmake_minimum_required(VERSION 2.8.12 FATAL_ERROR)

project(pq C)

set(CMAKE_COLOR_MAKEFILE ON)
set(CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake ${CMAKE_MODULE_PATH})

include(FindAnyProject)


include(GNUInstallDirs)

set(INSTALL_BIN_DIR ${CMAKE_INSTALL_BINDIR} CACHE INTERNAL "Installation directory for executables" FORCE)
set(INSTALL_LIB_DIR ${CMAKE_INSTALL_LIBDIR} CACHE INTERNAL "Installation directory for libraries" FORCE)
set(INSTALL_INC_DIR ${CMAKE_INSTALL_INCLUDEDIR} CACHE INTERNAL "Installation directory for headers" FORCE)

### Rename directories:
if(NOT INCLUDEDIR)
	set(INCLUDEDIR "${CMAKE_INSTALL_INCLUDEDIR}")
endif(NOT INCLUDEDIR)
if(NOT PKGINCLUDEDIR)
	set(PKGINCLUDEDIR "${CMAKE_INSTALL_INCLUDEDIR}")
endif(NOT PKGINCLUDEDIR)
if(NOT LIBDIR)
	set(LIBDIR "${CMAKE_INSTALL_LIBDIR}")
endif(NOT LIBDIR)
if(NOT PKGLIBDIR)
	set(PKGLIBDIR "${CMAKE_INSTALL_LIBDIR}")
endif(NOT PKGLIBDIR)

    
###set(POSTGRES_MAJOR_VERSION 9)
###set(POSTGRES_MINOR_VERSION 6)
###set(POSTGRES_PATCH_VERSION 0)
###set(POSTGRES_VERSION
###   ${POSTGRES_MAJOR_VERSION}.${POSTGRES_MINOR_VERSION}.${POSTGRES_PATCH_VERSION})
###set(PG_VERSION "9.6devel")
###set(PG_VERSION_NUM 90600)

### TODO: correct to obtain libpq version from this place?
include(util)
set_pq_version(VER_H_MAJOR VER_H_MINOR VER_H_RELEASE VER_H_BUILD)
set(LIBPQ_VERSION "${VER_H_MAJOR}.${VER_H_MINOR}.${VER_H_RELEASE}.${VER_H_BUILD}")
report_version(${PROJECT_NAME} ${LIBPQ_VERSION})


if(${CMAKE_SYSTEM_NAME} MATCHES "Darwin")
	set(CMAKE_SHARED_LINKER_FLAGS "-undefined dynamic_lookup")
endif()

if(${CMAKE_SYSTEM_NAME} MATCHES "FreeBSD|NetBSD|OpenBSD")
	set(CMAKE_SHARED_LIBRARY_SONAME_C_FLAG "-Wl,-x,-soname,")
endif()

if(${CMAKE_C_COMPILER_ID} STREQUAL "Clang")
	set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wno-ignored-attributes")
endif()

if(MSVC)
	set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} /D _CRT_SECURE_NO_WARNINGS")
endif()


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
###find_package(Threads)
find_anyproject(OpenSSL)###find_package(OpenSSL)
###find_package(ZLIB)
###find_package(PythonInterp)
###find_package(PythonLibs)
###find_package(SELinux)
###find_package(LibXml2)
###find_package(LibXslt)
###find_package(TCL)

if(OPENSSL_FOUND)
	set(USE_OPENSSL 1)
###	set(CMAKE_REQUIRED_INCLUDES ${OPENSSL_INCLUDE_DIR})
###	set(CMAKE_REQUIRED_LIBRARIES ${OPENSSL_LIBRARIES})
endif(OPENSSL_FOUND)

if(NOT MSVC)
	find_library(DL_LIBRARIES NAMES dl)
	find_library(M_LIB m)
endif()

if(NOT DL_LIBRARIES)
	set(DL_LIBRARIES "")
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

if(CMAKE_COMPILER_IS_GNUCC)
	# Disable strict-aliasing rules; needed for gcc 3.3+
	set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fno-strict-aliasing")
	# Disable FP optimizations that cause various errors on gcc 4.5+ or maybe 4.6+
	set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fwrapv")
	# Disable FP optimizations that cause various errors on gcc 4.5+ or maybe 4.6+
	set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fexcess-precision=standard")
endif()

if(CMAKE_C_COMPILER_ID STREQUAL "Intel")
	# Intel's compiler has a bug/misoptimization in checking for
	# division by NAN (NaN == 0), -mp1 fixes it, so add it to the CFLAGS.
	set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -mp1")
	# Make sure strict aliasing is off (though this is said to be the default)
	set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fno-strict-aliasing")
endif()

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

if(Threads_FOUND)
	set(ENABLE_THREAD_SAFETY 1)
	set(PTHREAD_CFLAGS "-D_REENTRANT -D_THREAD_SAFE -D_POSIX_PTHREAD_SEMANTICS")
	set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${PTHREAD_CFLAGS}")
	set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} ${CMAKE_THREAD_LIBS_INIT}")
endif()


if(NOT PGPORT)
	set(PGPORT 5432)
endif(NOT PGPORT)


### Do all configurations.
include(configure) 

### For generated configure files:
include_directories(${PROJECT_BINARY_DIR}/src/include)
include_directories(${PROJECT_BINARY_DIR}/src/port)


set(PORT_DIR "${PROJECT_SOURCE_DIR}/src/port")
set(PQ_BACKEND_DIR "${PROJECT_SOURCE_DIR}/src/backend/libpq")
set(MB_UTILS_BACKEND_DIR "${PROJECT_SOURCE_DIR}/src/backend/utils/mb")


set(fallback_SRCS "")
if(NOT HAVE_DECL_STRLCPY)
  set(fallback_SRCS ${fallback_SRCS} "${PORT_DIR}/strlcpy.c")
endif(NOT HAVE_DECL_STRLCPY)
if(NOT HAVE_DECL_STRLCAT)
  set(fallback_SRCS ${fallback_SRCS} "${PORT_DIR}/strlcat.c")
endif(NOT HAVE_DECL_STRLCAT)
if(NOT HAVE_GETPEEREID)
  set(fallback_SRCS ${fallback_SRCS} "${PORT_DIR}/getpeereid.c")
endif(NOT HAVE_GETPEEREID)

### The following added so not to use perl for replacing snprintf functions.
### Note: in msvc2013 there is no snprintf() function at all.
if(NOT HAVE_DECL_SNPRINTF) 
    add_definitions(-DUSE_REPL_SNPRINTF)
    set(fallback_SRCS ${fallback_SRCS} "${PORT_DIR}/snprintf.c")
endif(NOT HAVE_DECL_SNPRINTF)


if(WIN32)
	set(LIB_M "")
else()
	set(LIB_M m)
endif()


option(HAVE_SPINLOCKS "Define to ON if you have spinlocks." ON)
option(HAVE_ATOMICS "Define to ON if you want to use atomics if available." ON)
option(USE_INTEGER_DATETIMES "Define to ON if you want 64-bit integer timestamp and interval support." ON)
if(WIN32)
	option(HAVE_SYMLINK "Define to ON if you have the `symlink' function." ON)
else(WIN32)
	set(HAVE_SYMLINK 1)
endif(WIN32)
option(PG_KRB_SRVNAM "Define to the name of the default PostgreSQL service principal in Kerberos (GSSAPI)." "postgres")


if(WIN32)
	include_directories("${PROJECT_SOURCE_DIR}/src/include/port/win32")
endif()

if(MSVC)
	include_directories("${PROJECT_SOURCE_DIR}/src/include/port/win32_msvc")
endif()


### Define lib name in a common way.
set(LIB_NAME)
if(BUILD_SHARED_LIBS)
    set(LIB_TYPE SHARED)
    set(LIB_NAME ${PROJECT_NAME})
else()
    set(LIB_TYPE STATIC)
    set(LIB_NAME ${PROJECT_NAME}static)
endif()

set(EXPORT_TARGETS)

add_subdirectory(src)
###add_subdirectory(contrib)

### Install other headers.
# These headers are needed by the public headers of the interfaces.
install(FILES
	src/include/postgres_ext.h
	${PROJECT_BINARY_DIR}/src/include/pg_config.h
	${PROJECT_BINARY_DIR}/src/include/pg_config_ext.h
	${PROJECT_BINARY_DIR}/src/include/pg_config_os.h
###	src/include/pg_config_manual.h
	DESTINATION ${CMAKE_INSTALL_INCLUDEDIR})
install(FILES
	src/include/libpq/libpq-fs.h
	DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/libpq)

### Finally export libpq.
if(EXPORT_TARGETS)
    export(TARGETS ${EXPORT_TARGETS} FILE ${LIB_NAME}-exports.cmake EXPORT_LINK_INTERFACE_LIBRARIES)
endif()
