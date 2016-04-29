### CMake Postgres project: only for libpq external library. 

include_directories(BEFORE
	"${CMAKE_CURRENT_SOURCE_DIR}"
	"${PROJECT_SOURCE_DIR}/src/port"
)

include_directories(${CMAKE_CURRENT_SOURCE_DIR})

if(USE_OPENSSL)
	set(pq_ssl_SRCS fe-secure-openssl.c)
endif(USE_OPENSSL)

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

	${PORT_DIR}/chklocale.c
	${PORT_DIR}/inet_net_ntop.c
	${PORT_DIR}/noblock.c
	${PORT_DIR}/pgstrcasecmp.c
	${PORT_DIR}/pqsignal.c
	${PORT_DIR}/thread.c

	${PQ_BACKEND_DIR}/ip.c
	${PQ_BACKEND_DIR}/md5.c
	${MB_UTILS_BACKEND_DIR}/encnames.c
	${MB_UTILS_BACKEND_DIR}/wchar.c

	${fallback_SRCS}
	${pq_ssl_SRCS}
)

set(RES_FILES "")
if(WIN32)
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
	)
	if (Threads_FOUND)
		set(pq_SRCS ${pq_SRCS} pthread-win32.c)
	endif()
	set(RES_FILES "libpq.rc")
	set(CMAKE_RC_COMPILER_INIT windres)
	ENABLE_LANGUAGE(RC)
	SET(CMAKE_RC_COMPILE_OBJECT "<CMAKE_RC_COMPILER> <FLAGS> -O coff <DEFINES> -i <SOURCE> -o <OBJECT>")
endif()

add_library(${LIB_NAME} ${LIB_TYPE} ${pq_SRCS} ${RES_FILES})

target_link_extlibraries(${LIB_NAME})

if(WIN32)
	target_link_libraries(${LIB_NAME}
		#port
		Secur32
		ws2_32
	)
endif()

if(USE_OPENSSL)
	###target_include_directories(${LIB_NAME} PUBLIC ${OPENSSL_INCLUDE_DIR})
endif()
target_compile_definitions(${LIB_NAME} PRIVATE -DFRONTEND -DUNSAFE_STAT_OK)

#TODO 
#set_target_properties(pq PROPERTIES LINK_FLAGS "-Wl,--version-script=${CMAKE_CURRENT_SOURCE_DIR}/exports.list")

install(TARGETS ${LIB_NAME}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR})
    
### TODO: is it correct to install only these headers?
file(GLOB_RECURSE FINAL_HEADERS FOLOW_SYMLYNKS *.h)
install(FILES ${FINAL_HEADERS} DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/.)

set(EXPORT_TARGETS ${EXPORT_TARGETS} ${LIB_NAME} PARENT_SCOPE)

