# -----------------------------------------------------------------------------
# Findsml.cmake - Boost.SML, the state machine library (header-only, needs no
# Boost), as the target sml::sml
#
#   list(APPEND CMAKE_MODULE_PATH "<the folder of this file>")
#   find_package(sml REQUIRED)
#   target_link_libraries(my_app PRIVATE sml::sml)     # #include <boost/sml.hpp>
#
# Where it comes from:
#
#   1. SML_ROOT_DIR, when it is set (-DSML_ROOT_DIR=<dir>, a variable of the
#      calling project, or the environment variable of that name) and holds the
#      library: either an install prefix (the folder with lib/cmake/sml) or its
#      source tree.
#   2. Otherwise FetchContent clones SML_GIT_REPOSITORY at SML_GIT_TAG once into
#      SML_SOURCE_DIR and adds it to the calling project. Later configures, in
#      any build folder, use that copy as it is; delete the folder to fetch
#      again (e.g. for another tag).
#
# Variables, all optional, read when find_package() is called:
#
#   SML_ROOT_DIR            the library you have (see 1.)
#   SML_GIT_REPOSITORY      default: https://github.com/boost-ext/sml.git
#   SML_GIT_TAG             tag or branch; default: v1.2.0
#   SML_SOURCE_DIR          where the clone goes;
#                           default: ../extern/sml beside this file
#
# The repository can be on any git server (a mirror, offline): it is cloned
# without submodules. sml's own CMake always adds install rules, so installing
# the calling project installs sml's header and package files too.
#
# Result:
#
#   sml_FOUND               TRUE when the target exists
#   SML_DIR                 the library in use: its package folder (install
#                           prefix) or its source tree
#   SML_VERSION             its version
#
# A project that already has sml::sml uses it as it is.
# -----------------------------------------------------------------------------

if(TARGET sml::sml)
    set(sml_FOUND TRUE)
    return()
endif()

set(SML_ROOT_DIR "$ENV{SML_ROOT_DIR}"
    CACHE PATH "sml to use: an install prefix or a source tree (empty: fetch it with git)")

if(NOT SML_GIT_REPOSITORY)
    set(SML_GIT_REPOSITORY "https://github.com/boost-ext/sml.git")
endif()

if(NOT SML_GIT_TAG)
    set(SML_GIT_TAG "v1.2.0")
endif()

if(NOT SML_SOURCE_DIR)
    set(SML_SOURCE_DIR "${CMAKE_CURRENT_LIST_DIR}/../extern/sml")
endif()

# Full paths with forward slashes, however they were given (C:\libs\sml).
get_filename_component(SML_SOURCE_DIR "${SML_SOURCE_DIR}" ABSOLUTE)
if(SML_ROOT_DIR)
    get_filename_component(SML_ROOT_DIR "${SML_ROOT_DIR}" ABSOLUTE)
endif()

set(SML_DIR "")
set(SML_VERSION "")

# -----------------------------------------------------------------------------
# 1. SML_ROOT_DIR
# -----------------------------------------------------------------------------

set(_sml_tree "")               # a source tree to use, instead of the clone

if(SML_ROOT_DIR)

    find_package(sml CONFIG QUIET PATHS "${SML_ROOT_DIR}" NO_DEFAULT_PATH)

    if(sml_FOUND)
        set(SML_DIR "${sml_DIR}")
        set(SML_VERSION "${sml_VERSION}")
    elseif(EXISTS "${SML_ROOT_DIR}/smlConfig.cmake.in")
        set(_sml_tree "${SML_ROOT_DIR}")
    else()
        message(WARNING
            "sml: SML_ROOT_DIR is ${SML_ROOT_DIR}, which holds neither an installed sml "
            "(lib/cmake/sml) nor its sources. Using the fetched sml in ${SML_SOURCE_DIR} instead.")
    endif()

endif()

# -----------------------------------------------------------------------------
# 2. FetchContent, from the git repository
# -----------------------------------------------------------------------------

if(NOT SML_DIR)

    include(FetchContent)

    # A source tree that is there already (SML_ROOT_DIR, or fetched before,
    # possibly by another build folder): use it as it is.
    if(_sml_tree)
        set(FETCHCONTENT_SOURCE_DIR_SML "${_sml_tree}")
    elseif(EXISTS "${SML_SOURCE_DIR}/smlConfig.cmake.in")
        set(FETCHCONTENT_SOURCE_DIR_SML "${SML_SOURCE_DIR}")
    elseif(NOT sml_FIND_QUIETLY)
        message(STATUS "sml: fetching ${SML_GIT_TAG} from ${SML_GIT_REPOSITORY} "
                       "into ${SML_SOURCE_DIR} (set SML_ROOT_DIR to use one you have)")
    endif()

    # sml builds no tests, examples or benchmarks unless asked (SML_BUILD_*).

    FetchContent_Declare(
        sml
        GIT_REPOSITORY "${SML_GIT_REPOSITORY}"
        GIT_TAG "${SML_GIT_TAG}"
        GIT_SHALLOW TRUE
        GIT_SUBMODULES ""
        SOURCE_DIR "${SML_SOURCE_DIR}"
    )

    FetchContent_MakeAvailable(sml)

    unset(FETCHCONTENT_SOURCE_DIR_SML)

    if(TARGET sml::sml)
        set(SML_DIR "${sml_SOURCE_DIR}")

        # The version is the one the header itself declares (1'2'0).
        file(STRINGS "${sml_SOURCE_DIR}/include/boost/sml.hpp" _sml_version
             REGEX "#define BOOST_SML_VERSION ")
        string(REGEX MATCHALL "[0-9]+" _sml_version "${_sml_version}")
        list(JOIN _sml_version "." SML_VERSION)
        unset(_sml_version)
    endif()

endif()

unset(_sml_tree)

include(FindPackageHandleStandardArgs)

find_package_handle_standard_args(
    sml
    REQUIRED_VARS SML_DIR
    VERSION_VAR SML_VERSION
)
