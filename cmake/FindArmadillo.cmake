# -----------------------------------------------------------------------------
# FindArmadillo.cmake - Armadillo, linear algebra, as the target armadillo
#
#   list(APPEND CMAKE_MODULE_PATH "<the folder of this file>")
#   find_package(Armadillo REQUIRED)
#   target_link_libraries(my_app PRIVATE armadillo)
#
# Armadillo uses BLAS and LAPACK (OpenBLAS, MKL, ...) when its CMake finds them;
# without them it still builds, but without the functions that need LAPACK
# (solve, inv, eig, ...): its configure output says so. Its options STATIC_LIB
# and HEADER_ONLY choose how the target is built.
#
# Where it comes from:
#
#   1. ARMADILLO_ROOT_DIR, when it is set (-DARMADILLO_ROOT_DIR=<dir>, a
#      variable of the calling project, or the environment variable of that
#      name) and holds the library: either an install prefix (the folder with
#      share/Armadillo/CMake) or its source tree (also the unpacked release
#      archive from arma.sourceforge.net).
#   2. Otherwise FetchContent clones ARMADILLO_GIT_REPOSITORY at
#      ARMADILLO_GIT_TAG once into ARMADILLO_SOURCE_DIR and builds it as part
#      of the calling project. Later configures, in any build folder, use that
#      copy as it is; delete the folder to fetch again (e.g. for another tag).
#
# Variables, all optional, read when find_package() is called:
#
#   ARMADILLO_ROOT_DIR        the library you have (see 1.)
#   ARMADILLO_GIT_REPOSITORY  default: https://gitlab.com/armadillo-lib/armadillo-code.git
#   ARMADILLO_GIT_TAG         tag (15.6.2) or branch (15.6.x); default: 15.6.2
#   ARMADILLO_SOURCE_DIR      where the clone goes;
#                             default: ../extern/armadillo beside this file
#
# The repository can be on any git server (a mirror, offline): it is cloned
# without submodules.
#
# Result:
#
#   Armadillo_FOUND           TRUE when the target exists
#   ARMADILLO_DIR             the library in use: its package folder (install
#                             prefix) or its source tree
#   ARMADILLO_VERSION         its version
#
# A project that already has the target armadillo uses it as it is. In a
# project that lists the folder of this file in CMAKE_MODULE_PATH, this file is
# used instead of CMake's own FindArmadillo module.
# -----------------------------------------------------------------------------

if(TARGET armadillo)
    set(Armadillo_FOUND TRUE)
    return()
endif()

set(ARMADILLO_ROOT_DIR "$ENV{ARMADILLO_ROOT_DIR}"
    CACHE PATH "Armadillo to use: an install prefix or a source tree (empty: fetch it with git)")

if(NOT ARMADILLO_GIT_REPOSITORY)
    set(ARMADILLO_GIT_REPOSITORY "https://gitlab.com/armadillo-lib/armadillo-code.git")
endif()

if(NOT ARMADILLO_GIT_TAG)
    set(ARMADILLO_GIT_TAG "15.6.2")
endif()

if(NOT ARMADILLO_SOURCE_DIR)
    set(ARMADILLO_SOURCE_DIR "${CMAKE_CURRENT_LIST_DIR}/../extern/armadillo")
endif()

# Full paths with forward slashes, however they were given (C:\libs\armadillo).
get_filename_component(ARMADILLO_SOURCE_DIR "${ARMADILLO_SOURCE_DIR}" ABSOLUTE)
if(ARMADILLO_ROOT_DIR)
    get_filename_component(ARMADILLO_ROOT_DIR "${ARMADILLO_ROOT_DIR}" ABSOLUTE)
endif()

set(ARMADILLO_DIR "")
set(ARMADILLO_VERSION "")

# -----------------------------------------------------------------------------
# 1. ARMADILLO_ROOT_DIR
# -----------------------------------------------------------------------------

set(_armadillo_tree "")         # a source tree to build, instead of the clone

if(ARMADILLO_ROOT_DIR)

    find_package(Armadillo CONFIG QUIET PATHS "${ARMADILLO_ROOT_DIR}" NO_DEFAULT_PATH)

    if(Armadillo_FOUND)
        set(ARMADILLO_DIR "${Armadillo_DIR}")
        set(ARMADILLO_VERSION "${Armadillo_VERSION}")
    elseif(EXISTS "${ARMADILLO_ROOT_DIR}/src/wrapper1.cpp")
        set(_armadillo_tree "${ARMADILLO_ROOT_DIR}")
    else()
        message(WARNING
            "Armadillo: ARMADILLO_ROOT_DIR is ${ARMADILLO_ROOT_DIR}, which holds neither an "
            "installed Armadillo (ArmadilloConfig.cmake) nor its sources. Using the fetched "
            "Armadillo in ${ARMADILLO_SOURCE_DIR} instead.")
    endif()

endif()

# -----------------------------------------------------------------------------
# 2. FetchContent, from the git repository
# -----------------------------------------------------------------------------

if(NOT ARMADILLO_DIR)

    include(FetchContent)

    # A source tree that is there already (ARMADILLO_ROOT_DIR, or fetched
    # before, possibly by another build folder): use it as it is.
    if(_armadillo_tree)
        set(FETCHCONTENT_SOURCE_DIR_ARMADILLO "${_armadillo_tree}")
    elseif(EXISTS "${ARMADILLO_SOURCE_DIR}/src/wrapper1.cpp")
        set(FETCHCONTENT_SOURCE_DIR_ARMADILLO "${ARMADILLO_SOURCE_DIR}")
    elseif(NOT Armadillo_FIND_QUIETLY)
        message(STATUS "Armadillo: fetching ${ARMADILLO_GIT_TAG} from ${ARMADILLO_GIT_REPOSITORY} "
                       "into ${ARMADILLO_SOURCE_DIR} (set ARMADILLO_ROOT_DIR to use one you have)")
    endif()

    # Armadillo's own setting: no smoke test. CMP0077 NEW lets its option()
    # take it; CMP0090 NEW keeps it out of the user's CMake package registry.
    set(CMAKE_POLICY_DEFAULT_CMP0077 NEW)
    set(CMAKE_POLICY_DEFAULT_CMP0090 NEW)
    set(BUILD_SMOKE_TEST OFF)

    FetchContent_Declare(
        armadillo
        GIT_REPOSITORY "${ARMADILLO_GIT_REPOSITORY}"
        GIT_TAG "${ARMADILLO_GIT_TAG}"
        GIT_SHALLOW TRUE
        GIT_SUBMODULES ""
        SOURCE_DIR "${ARMADILLO_SOURCE_DIR}"
    )

    FetchContent_MakeAvailable(armadillo)

    unset(FETCHCONTENT_SOURCE_DIR_ARMADILLO)
    unset(CMAKE_POLICY_DEFAULT_CMP0077)
    unset(CMAKE_POLICY_DEFAULT_CMP0090)
    unset(BUILD_SMOKE_TEST)

    if(TARGET armadillo)
        set(ARMADILLO_DIR "${armadillo_SOURCE_DIR}")

        # The version is the one the header itself declares.
        file(STRINGS "${armadillo_SOURCE_DIR}/include/armadillo_bits/arma_version.hpp" _armadillo_version
             REGEX "#define ARMA_VERSION_(MAJOR|MINOR|PATCH) ")
        string(REGEX MATCHALL "[0-9]+" _armadillo_version "${_armadillo_version}")
        list(JOIN _armadillo_version "." ARMADILLO_VERSION)
        unset(_armadillo_version)
    endif()

endif()

unset(_armadillo_tree)

include(FindPackageHandleStandardArgs)

find_package_handle_standard_args(
    Armadillo
    REQUIRED_VARS ARMADILLO_DIR
    VERSION_VAR ARMADILLO_VERSION
)
