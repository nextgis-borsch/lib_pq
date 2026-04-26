### CMake Postgres project: only for libpq external library (PG 18+)

include_directories(BEFORE
	"${CMAKE_CURRENT_SOURCE_DIR}"
	"${PROJECT_SOURCE_DIR}/src/port"
)

include_directories(${CMAKE_CURRENT_SOURCE_DIR})

# Crypto (matches src/common/meson.build SSL vs. generic paths)
if(USE_OPENSSL)
	set(pq_ssl_SRCS
		fe-secure-common.c
		fe-secure-openssl.c
		${PROJECT_SOURCE_DIR}/src/common/cryptohash_openssl.c
		${PROJECT_SOURCE_DIR}/src/common/hmac_openssl.c
	)
else()
	set(pq_ssl_SRCS
		${PROJECT_SOURCE_DIR}/src/common/cryptohash.c
		${PROJECT_SOURCE_DIR}/src/common/hmac.c
		${PROJECT_SOURCE_DIR}/src/common/md5.c
		${PROJECT_SOURCE_DIR}/src/common/sha1.c
		${PROJECT_SOURCE_DIR}/src/common/sha2.c
	)
endif()

# Objects shared with pgcommon in autotools/meson; keep in sync with
# src/common/meson.build (frontend) for anything libpq includes.
# palloc/pfree in psprintf, stringinfo, etc. (postgres_fe + fe_memutils);
# pg_log_* in percentrepl (logging.c); fe-connect.c needs pg_prng_*
set(pq_common_SRCS
	${PROJECT_SOURCE_DIR}/src/common/fe_memutils.c
	${PROJECT_SOURCE_DIR}/src/common/logging.c
	${PROJECT_SOURCE_DIR}/src/common/pg_prng.c
	${PROJECT_SOURCE_DIR}/src/common/base64.c
	${PROJECT_SOURCE_DIR}/src/common/ip.c
	${PROJECT_SOURCE_DIR}/src/common/link-canary.c
	${PROJECT_SOURCE_DIR}/src/common/string.c
	${PROJECT_SOURCE_DIR}/src/common/file_perm.c
	${PROJECT_SOURCE_DIR}/src/common/encnames.c
	${PROJECT_SOURCE_DIR}/src/common/wchar.c
	${PROJECT_SOURCE_DIR}/src/common/scram-common.c
	${PROJECT_SOURCE_DIR}/src/common/saslprep.c
	${PROJECT_SOURCE_DIR}/src/common/unicode_norm.c
	${PROJECT_SOURCE_DIR}/src/common/unicode_case.c
	${PROJECT_SOURCE_DIR}/src/common/unicode_category.c
	${PROJECT_SOURCE_DIR}/src/common/psprintf.c
	${PROJECT_SOURCE_DIR}/src/common/stringinfo.c
	${PROJECT_SOURCE_DIR}/src/common/percentrepl.c
	${PROJECT_SOURCE_DIR}/src/common/md5_common.c
	${PROJECT_SOURCE_DIR}/src/common/jsonapi.c
)

set(pq_SRCS
	fe-auth.c
	fe-auth-oauth.c
	fe-auth-scram.c
	fe-cancel.c
	fe-connect.c
	fe-exec.c
	fe-misc.c
	fe-print.c
	fe-lobj.c
	fe-protocol3.c
	fe-secure.c
	fe-trace.c
	legacy-pqsignal.c
	pqexpbuffer.c
	libpq-events.c
	# portable subset of pgport (see src/port/meson.build)
	${PORT_DIR}/bsearch_arg.c
	${PORT_DIR}/chklocale.c
	${PORT_DIR}/inet_net_ntop.c
	${PORT_DIR}/noblock.c
	${PORT_DIR}/path.c
	${PORT_DIR}/pg_bitutils.c
	${PORT_DIR}/pg_strong_random.c
	${PORT_DIR}/pgcheckdir.c
	${PORT_DIR}/pgmkdirp.c
	${PORT_DIR}/pgsleep.c
	${PORT_DIR}/pgstrcasecmp.c
	${PORT_DIR}/pgstrsignal.c
	${PORT_DIR}/pqsignal.c
	${PORT_DIR}/qsort.c
	${PORT_DIR}/qsort_arg.c
	${PORT_DIR}/quotes.c
	${PORT_DIR}/snprintf.c
	${PORT_DIR}/strerror.c
	${PORT_DIR}/tar.c
	${PORT_DIR}/strnlen.c
	${PORT_DIR}/explicit_bzero.c
	${pq_common_SRCS}
	${fallback_SRCS}
	${pq_ssl_SRCS}
)

# jsonapi.c uses PQExpBuffer when built for libpq
set_source_files_properties(
	${PROJECT_SOURCE_DIR}/src/common/jsonapi.c
	PROPERTIES COMPILE_DEFINITIONS JSONAPI_USE_PQEXPBUFFER=1
)

if(ANDROID OR IOS)
	set(pq_SRCS ${pq_SRCS}
		${PORT_DIR}/pg_crc32c_armv8.c
		${PORT_DIR}/pg_crc32c_armv8_choose.c
		${PORT_DIR}/pg_crc32c_sse42_choose.c
	)
endif()

if(WIN32)
	set(pq_SRCS ${pq_SRCS}
		pthread-win32.c
		win32.c
		${PORT_DIR}/dirmod.c
		${PORT_DIR}/kill.c
		${PORT_DIR}/open.c
		${PORT_DIR}/system.c
		${PORT_DIR}/win32common.c
		${PORT_DIR}/win32dlopen.c
		${PORT_DIR}/win32env.c
		${PORT_DIR}/win32error.c
		${PORT_DIR}/win32fdatasync.c
		${PORT_DIR}/win32fseek.c
		${PORT_DIR}/win32gai_strerror.c
		${PORT_DIR}/win32getrusage.c
		${PORT_DIR}/win32gettimeofday.c
		${PORT_DIR}/win32link.c
		${PORT_DIR}/win32ntdll.c
		${PORT_DIR}/win32pread.c
		${PORT_DIR}/win32pwrite.c
		${PORT_DIR}/win32security.c
		${PORT_DIR}/win32setlocale.c
		${PORT_DIR}/win32stat.c
		${PORT_DIR}/inet_aton.c
	)
	# logging.c and other code use strsep(); MSVC has no strsep
	set(pq_SRCS ${pq_SRCS} ${PORT_DIR}/strsep.c)
	if(MSVC)
		set(pq_SRCS ${pq_SRCS} ${PORT_DIR}/dirent.c)
	endif()
	if(Threads_FOUND)
		# win32.c expects pthreads on Windows; pthread-win32 is listed above
	endif()
endif()

file(GLOB_RECURSE FINAL_HEADERS ${CMAKE_CURRENT_SOURCE_DIR}/*.h)
set(ALL_PUBLIC_HDRS_PQ ${FINAL_HEADERS} ${PUBLIC_HDRS} ${PUBLIC_HDRS_PQ})

if(MSVC_VERSION AND MSVC_VERSION LESS 1900)
	add_definitions(-Dinline=__inline)
endif()

if(USE_OPENSSL)
	add_definitions(-DUSE_OPENSSL_RANDOM)
endif()

# Upstream uses SO version 5 (see src/interfaces/libpq/meson.build)
if(NOT WIN32)
	set(_pq_soversion 5)
	set(_pq_sover "${_pq_soversion}.${POSTGRES_MAJOR_VERSION}")
else()
	set(_pq_soversion "${POSTGRES_MAJOR_VERSION}")
	set(_pq_sover "${VERSION}")
endif()

if(BUILD_SHARED_LIBS)
	add_library(${LIB_NAME} SHARED ${pq_SRCS} ${ALL_PUBLIC_HDRS_PQ})
	set_target_properties(${LIB_NAME} PROPERTIES
		SOVERSION ${_pq_soversion}
		VERSION "${_pq_sover}"
	)
	target_compile_definitions(${LIB_NAME} PRIVATE USE_DYNAMIC_OAUTH=1)
elseif(OSX_FRAMEWORK)
	add_library(${LIB_NAME} SHARED ${pq_SRCS} ${ALL_PUBLIC_HDRS_PQ})
	set_property(SOURCE ${PUBLIC_HDRS_PQ} PROPERTY MACOSX_PACKAGE_LOCATION "Headers/libpq")
	set_property(SOURCE ${PUBLIC_HDRS} PROPERTY MACOSX_PACKAGE_LOCATION "Headers")

	set_target_properties(${LIB_NAME} PROPERTIES
		SOVERSION ${_pq_soversion}
		VERSION "${_pq_sover}"
		FRAMEWORK TRUE
		FRAMEWORK_VERSION ${FRAMEWORK_VERSION}
		MACOSX_FRAMEWORK_SHORT_VERSION_STRING ${VERSION}
		MACOSX_FRAMEWORK_BUNDLE_VERSION ${VERSION}
		MACOSX_FRAMEWORK_IDENTIFIER org.postgresql.libpq
		XCODE_ATTRIBUTE_INSTALL_PATH "@rpath"
		PUBLIC_HEADER "${FINAL_HEADERS}"
	)
	target_compile_definitions(${LIB_NAME} PRIVATE USE_DYNAMIC_OAUTH=1)
else()
	add_library(${LIB_NAME} STATIC ${pq_SRCS} ${ALL_PUBLIC_HDRS_PQ})
	if(NOT WIN32)
		set_target_properties(${LIB_NAME} PROPERTIES
			SOVERSION ${_pq_soversion}
			VERSION "${_pq_sover}"
		)
	endif()
endif()

target_link_extlibraries(${LIB_NAME})
target_compile_definitions(${LIB_NAME} PRIVATE -DFRONTEND -DUNSAFE_STAT_OK)
# Match meson: libpq_c_args
target_compile_definitions(${LIB_NAME} PRIVATE SO_MAJOR_VERSION=5)

if(NOT SKIP_INSTALL_LIBRARIES AND NOT SKIP_INSTALL_ALL )
	install(TARGETS ${LIB_NAME}
		EXPORT ${PACKAGE_UPPER_NAME}Targets
		RUNTIME DESTINATION ${INSTALL_BIN_DIR}
		ARCHIVE DESTINATION ${INSTALL_LIB_DIR}
		LIBRARY DESTINATION ${INSTALL_LIB_DIR}
		INCLUDES DESTINATION ${INSTALL_INC_DIR}
		FRAMEWORK DESTINATION ${INSTALL_LIB_DIR}
	)
endif()

if(NOT SKIP_INSTALL_HEADERS AND NOT SKIP_INSTALL_ALL)
	install(FILES ${FINAL_HEADERS} DESTINATION ${INSTALL_INC_DIR})
endif()

# Add path to includes to build-tree export
target_include_directories(${LIB_NAME} PUBLIC
	$<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}/src/include>
	$<BUILD_INTERFACE:${CMAKE_BINARY_DIR}/src/include>
	$<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}/src/port>
	$<BUILD_INTERFACE:${CMAKE_BINARY_DIR}/src/port>
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
)

# Add all targets to the build-tree export set
export(TARGETS ${LIB_NAME}
	FILE ${PROJECT_BINARY_DIR}/${PACKAGE_UPPER_NAME}Targets.cmake)

if(NOT SKIP_INSTALL_LIBRARIES AND NOT SKIP_INSTALL_ALL)
	install(FILES
		${PROJECT_BINARY_DIR}/${PACKAGE_UPPER_NAME}Config.cmake
		DESTINATION ${INSTALL_CMAKECONF_DIR} COMPONENT dev)
	install(EXPORT ${PACKAGE_UPPER_NAME}Targets DESTINATION ${INSTALL_CMAKECONF_DIR} COMPONENT dev)
endif()
