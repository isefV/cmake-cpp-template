# -----------------------------------------------------------------------------
# FindZeroMQ.cmake - libzmq, the ZeroMQ messaging library (C API), as the
# targets libzmq (shared) and libzmq-static
#
#   list(APPEND CMAKE_MODULE_PATH "<the folder of this file>")
#   find_package(ZeroMQ REQUIRED)
#   target_link_libraries(my_app PRIVATE libzmq)       # or libzmq-static
#
# For the C++ API (zmq.hpp) use Findcppzmq.cmake, which finds this one itself.
# libzmq builds both libraries; its options BUILD_SHARED and BUILD_STATIC turn
# one of them off.
#
# Where it comes from:
#
#   1. ZEROMQ_ROOT_DIR, when it is set (-DZEROMQ_ROOT_DIR=<dir>, a variable of
#      the calling project, or the environment variable of that name) and holds
#      the library: either an install prefix (the folder with lib/cmake/ZeroMQ
#      or CMake/ZeroMQConfig.cmake) or its source tree.
#   2. Otherwise FetchContent clones ZEROMQ_GIT_REPOSITORY at ZEROMQ_GIT_TAG
#      once into ZEROMQ_SOURCE_DIR and builds it as part of the calling
#      project. Later configures, in any build folder, use that copy as it is;
#      delete the folder to fetch again (e.g. for another tag).
#
# Variables, all optional, read when find_package() is called:
#
#   ZEROMQ_ROOT_DIR         the library you have (see 1.)
#   ZEROMQ_GIT_REPOSITORY   default: https://github.com/zeromq/libzmq.git
#   ZEROMQ_GIT_TAG          tag or branch; default: v4.3.5
#   ZEROMQ_SOURCE_DIR       where the clone goes;
#                           default: ../extern/libzmq beside this file
#
# The repository can be on any git server (a mirror, offline): it is cloned
# without submodules.
#
# Result:
#
#   ZeroMQ_FOUND            TRUE when libzmq or libzmq-static exists
#   ZEROMQ_DIR              the library in use: its package folder (install
#                           prefix) or its source tree
#   ZEROMQ_VERSION          its version
#
# A project that already has libzmq or libzmq-static uses it as it is.
# -----------------------------------------------------------------------------

if(TARGET libzmq OR TARGET libzmq-static)
    set(ZeroMQ_FOUND TRUE)
    return()
endif()

set(ZEROMQ_ROOT_DIR "$ENV{ZEROMQ_ROOT_DIR}"
    CACHE PATH "libzmq to use: an install prefix or a source tree (empty: fetch it with git)")

if(NOT ZEROMQ_GIT_REPOSITORY)
    set(ZEROMQ_GIT_REPOSITORY "https://github.com/zeromq/libzmq.git")
endif()

if(NOT ZEROMQ_GIT_TAG)
    set(ZEROMQ_GIT_TAG "v4.3.5")
endif()

if(NOT ZEROMQ_SOURCE_DIR)
    set(ZEROMQ_SOURCE_DIR "${CMAKE_CURRENT_LIST_DIR}/../extern/libzmq")
endif()

# Full paths with forward slashes, however they were given (C:\libs\libzmq).
get_filename_component(ZEROMQ_SOURCE_DIR "${ZEROMQ_SOURCE_DIR}" ABSOLUTE)
if(ZEROMQ_ROOT_DIR)
    get_filename_component(ZEROMQ_ROOT_DIR "${ZEROMQ_ROOT_DIR}" ABSOLUTE)
endif()

set(ZEROMQ_DIR "")
set(ZEROMQ_VERSION "")

# -----------------------------------------------------------------------------
# 1. ZEROMQ_ROOT_DIR
# -----------------------------------------------------------------------------

set(_zeromq_tree "")            # a source tree to build, instead of the clone

if(ZEROMQ_ROOT_DIR)

    find_package(ZeroMQ CONFIG QUIET PATHS "${ZEROMQ_ROOT_DIR}" NO_DEFAULT_PATH)

    if(ZeroMQ_FOUND)
        set(ZEROMQ_DIR "${ZeroMQ_DIR}")
        set(ZEROMQ_VERSION "${ZeroMQ_VERSION}")
    elseif(EXISTS "${ZEROMQ_ROOT_DIR}/src/zmq.cpp")
        set(_zeromq_tree "${ZEROMQ_ROOT_DIR}")
    else()
        message(WARNING
            "ZeroMQ: ZEROMQ_ROOT_DIR is ${ZEROMQ_ROOT_DIR}, which holds neither an installed "
            "libzmq (ZeroMQConfig.cmake) nor its sources. Using the fetched libzmq in "
            "${ZEROMQ_SOURCE_DIR} instead.")
    endif()

endif()

# -----------------------------------------------------------------------------
# 2. FetchContent, from the git repository
# -----------------------------------------------------------------------------

if(NOT ZEROMQ_DIR)

    include(FetchContent)

    # A source tree that is there already (ZEROMQ_ROOT_DIR, or fetched before,
    # possibly by another build folder): use it as it is.
    if(_zeromq_tree)
        set(FETCHCONTENT_SOURCE_DIR_LIBZMQ "${_zeromq_tree}")
    elseif(EXISTS "${ZEROMQ_SOURCE_DIR}/src/zmq.cpp")
        set(FETCHCONTENT_SOURCE_DIR_LIBZMQ "${ZEROMQ_SOURCE_DIR}")
    elseif(NOT ZeroMQ_FIND_QUIETLY)
        message(STATUS "ZeroMQ: fetching ${ZEROMQ_GIT_TAG} from ${ZEROMQ_GIT_REPOSITORY} "
                       "into ${ZEROMQ_SOURCE_DIR} (set ZEROMQ_ROOT_DIR to use one you have)")
    endif()

    # libzmq 4.3.5 asks for CMake 2.8.12, which CMake 4 no longer accepts;
    # 3.5 is the oldest it does. CMP0077 NEW lets libzmq's option()s take the
    # values below: no tests, perf tools, docs or CPack rules, and no
    # precompiled header (with MSVC and Ninja two rules would write it). libzmq
    # runs include(FindThreads), which would warn about the name inside this
    # file.
    set(CMAKE_POLICY_VERSION_MINIMUM 3.5)
    set(CMAKE_POLICY_DEFAULT_CMP0077 NEW)
    set(FPHSA_NAME_MISMATCHED TRUE)
    set(BUILD_TESTS OFF)
    set(WITH_PERF_TOOL OFF)
    set(WITH_DOCS OFF)
    set(ENABLE_CPACK OFF)
    set(ENABLE_PRECOMPILED OFF)

    # libzmq 4.3.5 cannot compile its ipc:// transport with MinGW (fixed after
    # 4.3.5): without it. tcp:// and inproc:// work.
    if(MINGW)
        set(ZMQ_HAVE_IPC OFF)
    endif()

    FetchContent_Declare(
        libzmq
        GIT_REPOSITORY "${ZEROMQ_GIT_REPOSITORY}"
        GIT_TAG "${ZEROMQ_GIT_TAG}"
        GIT_SHALLOW TRUE
        GIT_SUBMODULES ""
        SOURCE_DIR "${ZEROMQ_SOURCE_DIR}"
    )

    FetchContent_MakeAvailable(libzmq)

    unset(FETCHCONTENT_SOURCE_DIR_LIBZMQ)
    unset(CMAKE_POLICY_VERSION_MINIMUM)
    unset(CMAKE_POLICY_DEFAULT_CMP0077)
    unset(FPHSA_NAME_MISMATCHED)
    unset(BUILD_TESTS)
    unset(WITH_PERF_TOOL)
    unset(WITH_DOCS)
    unset(ENABLE_CPACK)
    unset(ENABLE_PRECOMPILED)
    unset(ZMQ_HAVE_IPC)

    if(TARGET libzmq OR TARGET libzmq-static)
        set(ZEROMQ_DIR "${libzmq_SOURCE_DIR}")

        # The version is the one the header itself declares.
        file(STRINGS "${libzmq_SOURCE_DIR}/include/zmq.h" _zeromq_version
             REGEX "#define ZMQ_VERSION_(MAJOR|MINOR|PATCH) ")
        string(REGEX MATCHALL "[0-9]+" _zeromq_version "${_zeromq_version}")
        list(JOIN _zeromq_version "." ZEROMQ_VERSION)
        unset(_zeromq_version)
    endif()

endif()

unset(_zeromq_tree)

include(FindPackageHandleStandardArgs)

find_package_handle_standard_args(
    ZeroMQ
    REQUIRED_VARS ZEROMQ_DIR
    VERSION_VAR ZEROMQ_VERSION
)
