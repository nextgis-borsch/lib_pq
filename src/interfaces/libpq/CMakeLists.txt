### CMake Postgres project: only for libpq external library.

include_directories(BEFORE
	"${CMAKE_CURRENT_SOURCE_DIR}"
	"${PROJECT_SOURCE_DIR}/src/port"
)

include_directories(${CMAKE_CURRENT_SOURCE_DIR})

if(USE_OPENSSL)
	set(pq_ssl_SRCS fe-secure-openssl.c ${PROJECT_SOURCE_DIR}/src/common/sha2_openssl.c)
else()
    set(pq_ssl_SRCS ${PROJECT_SOURCE_DIR}/src/common/sha2.c)
endif()

set(pq_SRCS
	fe-auth.c
	fe-connect.c
	fe-exec.c
	fe-misc.c
	fe-print.c
	fe-lobj.c
	fe-protocol2.c
	fe-protocol3.c
	pqexpbuffer.c
	fe-secure.c
	libpq-events.c
    fe-auth-scram.c

	${PORT_DIR}/chklocale.c
	${PORT_DIR}/erand48.c
	${PORT_DIR}/inet_net_ntop.c
	${PORT_DIR}/noblock.c
	${PORT_DIR}/pgstrcasecmp.c
	${PORT_DIR}/pqsignal.c
	${PORT_DIR}/thread.c

    ${PROJECT_SOURCE_DIR}/src/common/base64.c
	${PROJECT_SOURCE_DIR}/src/common/ip.c
	${PROJECT_SOURCE_DIR}/src/common/md5.c
	${PROJECT_SOURCE_DIR}/src/common/scram-common.c
	${PROJECT_SOURCE_DIR}/src/common/saslprep.c
	${PROJECT_SOURCE_DIR}/src/common/unicode_norm.c
	${MB_UTILS_BACKEND_DIR}/encnames.c
	${MB_UTILS_BACKEND_DIR}/wchar.c

	${fallback_SRCS}
	${pq_ssl_SRCS}
)

if(WIN32)
	configure_file(libpq.rc.in ${CMAKE_CURRENT_BINARY_DIR}/libpq.rc)
    if (CMAKE_BUILD_TYPE STREQUAL "Debug" OR CMAKE_BUILD_TYPE STREQUAL "RelWithDebInfo")
        set(pq_SRCS ${pq_SRCS} ${CMAKE_CURRENT_SOURCE_DIR}/libpqddll.def)
    else()
        set(pq_SRCS ${pq_SRCS} ${CMAKE_CURRENT_SOURCE_DIR}/libpqdll.def)
    endif()

	set(pq_SRCS ${pq_SRCS}
		win32.c
		${PORT_DIR}/win32error.c
		${PORT_DIR}/win32setlocale.c
		${PORT_DIR}/pgsleep.c
		${PORT_DIR}/open.c
		${PORT_DIR}/system.c
		${PORT_DIR}/inet_aton.c
		${PORT_DIR}/thread.c
		${PORT_DIR}/getaddrinfo.c
        ${PORT_DIR}/gettimeofday.c
		${CMAKE_CURRENT_BINARY_DIR}/libpq.rc
	)
	if (Threads_FOUND)
		set(pq_SRCS ${pq_SRCS} pthread-win32.c)
	endif()
endif()

file(GLOB_RECURSE FINAL_HEADERS FOLOW_SYMLYNKS ${CMAKE_CURRENT_SOURCE_DIR}/*.h)
set(ALL_PUBLIC_HDRS_PQ ${FINAL_HEADERS} ${PUBLIC_HDRS} ${PUBLIC_HDRS_PQ})

if(MSVC_VERSION LESS 1900)
    add_definitions(-Dinline=__inline)
endif()

# TODO:
#set_target_properties(pq PROPERTIES LINK_FLAGS "-Wl,--version-script=${CMAKE_CURRENT_SOURCE_DIR}/exports.list")

if(BUILD_SHARED_LIBS)
    add_library(${LIB_NAME} SHARED ${pq_SRCS} ${ALL_PUBLIC_HDRS_PQ})
    set_target_properties(${LIB_NAME} PROPERTIES
        SOVERSION ${POSTGRES_MAJOR_VERSION}
        VERSION ${VERSION}
    )
elseif(OSX_FRAMEWORK)
    add_library(${LIB_NAME} SHARED ${pq_SRCS} ${ALL_PUBLIC_HDRS_PQ})
    set_property(SOURCE ${PUBLIC_HDRS_PQ} PROPERTY MACOSX_PACKAGE_LOCATION "Headers/libpq")
    set_property(SOURCE ${PUBLIC_HDRS} PROPERTY MACOSX_PACKAGE_LOCATION "Headers")
    #set_property(SOURCE ${FINAL_HEADERS} PROPERTY MACOSX_PACKAGE_LOCATION "Headers/libpq")

    set_target_properties(${LIB_NAME} PROPERTIES
        SOVERSION ${POSTGRES_MAJOR_VERSION}
        VERSION ${VERSION}
        FRAMEWORK TRUE
        FRAMEWORK_VERSION ${FRAMEWORK_VERSION}
        MACOSX_FRAMEWORK_SHORT_VERSION_STRING ${VERSION}
        MACOSX_FRAMEWORK_BUNDLE_VERSION ${VERSION}
        MACOSX_FRAMEWORK_IDENTIFIER org.postgresql.libpq
        XCODE_ATTRIBUTE_INSTALL_PATH "@rpath"
        PUBLIC_HEADER "${FINAL_HEADERS}"
    )
else()
    add_library(${LIB_NAME} STATIC ${pq_SRCS} ${ALL_PUBLIC_HDRS_PQ})
    set_target_properties(${LIB_NAME} PROPERTIES
        SOVERSION ${POSTGRES_MAJOR_VERSION}
        VERSION ${VERSION}
    )
endif()

target_link_extlibraries(${LIB_NAME})
target_compile_definitions(${LIB_NAME} PRIVATE -DFRONTEND -DUNSAFE_STAT_OK)

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
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/src/include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}/src/include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}/src/port>
)

# Add all targets to the build-tree export set
export(TARGETS ${LIB_NAME}
    FILE ${PROJECT_BINARY_DIR}/${PACKAGE_UPPER_NAME}Targets.cmake)

if(NOT SKIP_INSTALL_LIBRARIES AND NOT SKIP_INSTALL_ALL)
    # Install the <Package>Config.cmake
    install(FILES
      ${PROJECT_BINARY_DIR}/${PACKAGE_UPPER_NAME}Config.cmake
      DESTINATION ${INSTALL_CMAKECONF_DIR} COMPONENT dev)

    # Install the export set for use with the install-tree
    install(EXPORT ${PACKAGE_UPPER_NAME}Targets DESTINATION ${INSTALL_CMAKECONF_DIR} COMPONENT dev)
endif()
