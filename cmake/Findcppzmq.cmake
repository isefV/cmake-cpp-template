# -----------------------------------------------------------------------------
# Findcppzmq.cmake - cppzmq, the C++ API of ZeroMQ (header-only, zmq.hpp), as
# the targets cppzmq (uses libzmq) and cppzmq-static (uses libzmq-static)
#
#   list(APPEND CMAKE_MODULE_PATH "<the folder of this file>")
#   find_package(cppzmq REQUIRED)
#   target_link_libraries(my_app PRIVATE cppzmq)       # or cppzmq-static
#
# cppzmq needs libzmq: a project that has its targets already (libzmq or
# libzmq-static) uses them, otherwise FindZeroMQ.cmake beside this file finds
# or fetches it.
#
# Where cppzmq comes from:
#
#   1. CPPZMQ_ROOT_DIR, when it is set (-DCPPZMQ_ROOT_DIR=<dir>, a variable of
#      the calling project, or the environment variable of that name) and holds
#      the library: either an install prefix (the folder with
#      share/cmake/cppzmq) or its source tree.
#   2. Otherwise FetchContent clones CPPZMQ_GIT_REPOSITORY at CPPZMQ_GIT_TAG
#      once into CPPZMQ_SOURCE_DIR and adds it to the calling project. Later
#      configures, in any build folder, use that copy as it is; delete the
#      folder to fetch again (e.g. for another tag).
#
# Variables, all optional, read when find_package() is called:
#
#   CPPZMQ_ROOT_DIR         the library you have (see 1.)
#   CPPZMQ_GIT_REPOSITORY   default: https://github.com/zeromq/cppzmq.git
#   CPPZMQ_GIT_TAG          tag or branch; default: v4.11.0
#   CPPZMQ_SOURCE_DIR       where the clone goes;
#                           default: ../extern/cppzmq beside this file
#
# The repository can be on any git server (a mirror, offline): it is cloned
# without submodules. cppzmq's own CMake always adds install rules, so
# installing the calling project installs zmq.hpp and cppzmq's package files.
#
# Result:
#
#   cppzmq_FOUND            TRUE when the target cppzmq exists
#   CPPZMQ_DIR              the library in use: its package folder (install
#                           prefix) or its source tree
#   CPPZMQ_VERSION          its version
#
# A project that already has the target cppzmq uses it as it is.
# -----------------------------------------------------------------------------

if(TARGET cppzmq)
    set(cppzmq_FOUND TRUE)
    return()
endif()

if(NOT TARGET libzmq AND NOT TARGET libzmq-static)
    find_package(ZeroMQ QUIET)
endif()

set(CPPZMQ_ROOT_DIR "$ENV{CPPZMQ_ROOT_DIR}"
    CACHE PATH "cppzmq to use: an install prefix or a source tree (empty: fetch it with git)")

if(NOT CPPZMQ_GIT_REPOSITORY)
    set(CPPZMQ_GIT_REPOSITORY "https://github.com/zeromq/cppzmq.git")
endif()

if(NOT CPPZMQ_GIT_TAG)
    set(CPPZMQ_GIT_TAG "v4.11.0")
endif()

if(NOT CPPZMQ_SOURCE_DIR)
    set(CPPZMQ_SOURCE_DIR "${CMAKE_CURRENT_LIST_DIR}/../extern/cppzmq")
endif()

# Full paths with forward slashes, however they were given (C:\libs\cppzmq).
get_filename_component(CPPZMQ_SOURCE_DIR "${CPPZMQ_SOURCE_DIR}" ABSOLUTE)
if(CPPZMQ_ROOT_DIR)
    get_filename_component(CPPZMQ_ROOT_DIR "${CPPZMQ_ROOT_DIR}" ABSOLUTE)
endif()

set(CPPZMQ_DIR "")
set(CPPZMQ_VERSION "")

# -----------------------------------------------------------------------------
# 1. CPPZMQ_ROOT_DIR
# -----------------------------------------------------------------------------

set(_cppzmq_tree "")            # a source tree to use, instead of the clone

if(CPPZMQ_ROOT_DIR)

    find_package(cppzmq CONFIG QUIET PATHS "${CPPZMQ_ROOT_DIR}" NO_DEFAULT_PATH)

    if(cppzmq_FOUND)
        set(CPPZMQ_DIR "${cppzmq_DIR}")
        set(CPPZMQ_VERSION "${cppzmq_VERSION}")
    elseif(EXISTS "${CPPZMQ_ROOT_DIR}/zmq.hpp")
        set(_cppzmq_tree "${CPPZMQ_ROOT_DIR}")
    else()
        message(WARNING
            "cppzmq: CPPZMQ_ROOT_DIR is ${CPPZMQ_ROOT_DIR}, which holds neither an installed "
            "cppzmq (share/cmake/cppzmq) nor its sources. Using the fetched cppzmq in "
            "${CPPZMQ_SOURCE_DIR} instead.")
    endif()

endif()

# -----------------------------------------------------------------------------
# 2. FetchContent, from the git repository (only with libzmq)
# -----------------------------------------------------------------------------

if(NOT CPPZMQ_DIR AND (TARGET libzmq OR TARGET libzmq-static))

    include(FetchContent)

    # A source tree that is there already (CPPZMQ_ROOT_DIR, or fetched before,
    # possibly by another build folder): use it as it is.
    if(_cppzmq_tree)
        set(FETCHCONTENT_SOURCE_DIR_CPPZMQ "${_cppzmq_tree}")
    elseif(EXISTS "${CPPZMQ_SOURCE_DIR}/zmq.hpp")
        set(FETCHCONTENT_SOURCE_DIR_CPPZMQ "${CPPZMQ_SOURCE_DIR}")
    elseif(NOT cppzmq_FIND_QUIETLY)
        message(STATUS "cppzmq: fetching ${CPPZMQ_GIT_TAG} from ${CPPZMQ_GIT_REPOSITORY} "
                       "into ${CPPZMQ_SOURCE_DIR} (set CPPZMQ_ROOT_DIR to use one you have)")
    endif()

    # cppzmq's own setting: no tests. CMP0077 NEW lets its option() take it.
    set(CMAKE_POLICY_DEFAULT_CMP0077 NEW)
    set(CPPZMQ_BUILD_TESTS OFF)

    FetchContent_Declare(
        cppzmq
        GIT_REPOSITORY "${CPPZMQ_GIT_REPOSITORY}"
        GIT_TAG "${CPPZMQ_GIT_TAG}"
        GIT_SHALLOW TRUE
        GIT_SUBMODULES ""
        SOURCE_DIR "${CPPZMQ_SOURCE_DIR}"
    )

    FetchContent_MakeAvailable(cppzmq)

    unset(FETCHCONTENT_SOURCE_DIR_CPPZMQ)
    unset(CMAKE_POLICY_DEFAULT_CMP0077)
    unset(CPPZMQ_BUILD_TESTS)

    if(TARGET cppzmq)
        set(CPPZMQ_DIR "${cppzmq_SOURCE_DIR}")

        # The version is the one the header itself declares.
        file(STRINGS "${cppzmq_SOURCE_DIR}/zmq.hpp" _cppzmq_version
             REGEX "#define CPPZMQ_VERSION_(MAJOR|MINOR|PATCH) ")
        string(REGEX MATCHALL "[0-9]+" _cppzmq_version "${_cppzmq_version}")
        list(JOIN _cppzmq_version "." CPPZMQ_VERSION)
        unset(_cppzmq_version)
    endif()

endif()

unset(_cppzmq_tree)

include(FindPackageHandleStandardArgs)

find_package_handle_standard_args(
    cppzmq
    REQUIRED_VARS CPPZMQ_DIR
    VERSION_VAR CPPZMQ_VERSION
    REASON_FAILURE_MESSAGE "cppzmq needs libzmq (FindZeroMQ.cmake, or the targets libzmq / libzmq-static)"
)
