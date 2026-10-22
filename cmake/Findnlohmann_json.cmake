# -----------------------------------------------------------------------------
# Findnlohmann_json.cmake - JSON for Modern C++ (header-only), as the target
# nlohmann_json::nlohmann_json
#
#   list(APPEND CMAKE_MODULE_PATH "<the folder of this file>")
#   find_package(nlohmann_json REQUIRED)
#   target_link_libraries(my_app PRIVATE nlohmann_json::nlohmann_json)
#
# Where it comes from:
#
#   1. NLOHMANN_JSON_ROOT_DIR, when it is set (-DNLOHMANN_JSON_ROOT_DIR=<dir>, a
#      variable of the calling project, or the environment variable of that
#      name) and holds the library: either an install prefix (the folder with
#      share/cmake/nlohmann_json) or its source tree.
#   2. Otherwise FetchContent clones NLOHMANN_JSON_GIT_REPOSITORY at
#      NLOHMANN_JSON_GIT_TAG once into NLOHMANN_JSON_SOURCE_DIR and adds it to
#      the calling project. Later configures, in any build folder, use that
#      copy as it is; delete the folder to fetch again (e.g. for another tag).
#
# Variables, all optional, read when find_package() is called:
#
#   NLOHMANN_JSON_ROOT_DIR        the library you have (see 1.)
#   NLOHMANN_JSON_GIT_REPOSITORY  default: https://github.com/nlohmann/json.git
#   NLOHMANN_JSON_GIT_TAG         tag or branch; default: v3.12.0
#   NLOHMANN_JSON_SOURCE_DIR      where the clone goes;
#                                 default: ../extern/nlohmann_json beside this file
#
# The repository can be on any git server (a mirror, offline): it is cloned
# without submodules.
#
# Result:
#
#   nlohmann_json_FOUND           TRUE when the target exists
#   NLOHMANN_JSON_DIR             the library in use: its package folder
#                                 (install prefix) or its source tree
#   NLOHMANN_JSON_VERSION         its version
#
# A project that already has nlohmann_json::nlohmann_json uses it as it is.
# -----------------------------------------------------------------------------

if(TARGET nlohmann_json::nlohmann_json)
    set(nlohmann_json_FOUND TRUE)
    return()
endif()

set(NLOHMANN_JSON_ROOT_DIR "$ENV{NLOHMANN_JSON_ROOT_DIR}"
    CACHE PATH "nlohmann_json to use: an install prefix or a source tree (empty: fetch it with git)")

if(NOT NLOHMANN_JSON_GIT_REPOSITORY)
    set(NLOHMANN_JSON_GIT_REPOSITORY "https://github.com/nlohmann/json.git")
endif()

if(NOT NLOHMANN_JSON_GIT_TAG)
    set(NLOHMANN_JSON_GIT_TAG "v3.12.0")
endif()

if(NOT NLOHMANN_JSON_SOURCE_DIR)
    set(NLOHMANN_JSON_SOURCE_DIR "${CMAKE_CURRENT_LIST_DIR}/../extern/nlohmann_json")
endif()

# Full paths with forward slashes, however they were given (C:\libs\json).
get_filename_component(NLOHMANN_JSON_SOURCE_DIR "${NLOHMANN_JSON_SOURCE_DIR}" ABSOLUTE)
if(NLOHMANN_JSON_ROOT_DIR)
    get_filename_component(NLOHMANN_JSON_ROOT_DIR "${NLOHMANN_JSON_ROOT_DIR}" ABSOLUTE)
endif()

set(NLOHMANN_JSON_DIR "")
set(NLOHMANN_JSON_VERSION "")

# -----------------------------------------------------------------------------
# 1. NLOHMANN_JSON_ROOT_DIR
# -----------------------------------------------------------------------------

set(_nlohmann_json_tree "")     # a source tree to use, instead of the clone

if(NLOHMANN_JSON_ROOT_DIR)

    find_package(nlohmann_json CONFIG QUIET PATHS "${NLOHMANN_JSON_ROOT_DIR}" NO_DEFAULT_PATH)

    if(nlohmann_json_FOUND)
        set(NLOHMANN_JSON_DIR "${nlohmann_json_DIR}")
        set(NLOHMANN_JSON_VERSION "${nlohmann_json_VERSION}")
    elseif(EXISTS "${NLOHMANN_JSON_ROOT_DIR}/single_include/nlohmann/json.hpp")
        set(_nlohmann_json_tree "${NLOHMANN_JSON_ROOT_DIR}")
    else()
        message(WARNING
            "nlohmann_json: NLOHMANN_JSON_ROOT_DIR is ${NLOHMANN_JSON_ROOT_DIR}, which holds "
            "neither an installed nlohmann_json nor its sources. Using the fetched "
            "nlohmann_json in ${NLOHMANN_JSON_SOURCE_DIR} instead.")
    endif()

endif()

# -----------------------------------------------------------------------------
# 2. FetchContent, from the git repository
# -----------------------------------------------------------------------------

if(NOT NLOHMANN_JSON_DIR)

    include(FetchContent)

    # A source tree that is there already (NLOHMANN_JSON_ROOT_DIR, or fetched
    # before, possibly by another build folder): use it as it is.
    if(_nlohmann_json_tree)
        set(FETCHCONTENT_SOURCE_DIR_NLOHMANN_JSON "${_nlohmann_json_tree}")
    elseif(EXISTS "${NLOHMANN_JSON_SOURCE_DIR}/single_include/nlohmann/json.hpp")
        set(FETCHCONTENT_SOURCE_DIR_NLOHMANN_JSON "${NLOHMANN_JSON_SOURCE_DIR}")
    elseif(NOT nlohmann_json_FIND_QUIETLY)
        message(STATUS "nlohmann_json: fetching ${NLOHMANN_JSON_GIT_TAG} from ${NLOHMANN_JSON_GIT_REPOSITORY} "
                       "into ${NLOHMANN_JSON_SOURCE_DIR} (set NLOHMANN_JSON_ROOT_DIR to use one you have)")
    endif()

    # As part of another project nlohmann_json adds no tests and no install
    # rules (JSON_BuildTests, JSON_Install).

    FetchContent_Declare(
        nlohmann_json
        GIT_REPOSITORY "${NLOHMANN_JSON_GIT_REPOSITORY}"
        GIT_TAG "${NLOHMANN_JSON_GIT_TAG}"
        GIT_SHALLOW TRUE
        GIT_SUBMODULES ""
        SOURCE_DIR "${NLOHMANN_JSON_SOURCE_DIR}"
    )

    FetchContent_MakeAvailable(nlohmann_json)

    unset(FETCHCONTENT_SOURCE_DIR_NLOHMANN_JSON)

    if(TARGET nlohmann_json::nlohmann_json)
        set(NLOHMANN_JSON_DIR "${nlohmann_json_SOURCE_DIR}")

        # The version is the one the source tree itself declares.
        file(STRINGS "${nlohmann_json_SOURCE_DIR}/CMakeLists.txt" _nlohmann_json_version
             REGEX "project\\(nlohmann_json VERSION [0-9.]+")
        string(REGEX MATCHALL "[0-9]+" _nlohmann_json_version "${_nlohmann_json_version}")
        list(JOIN _nlohmann_json_version "." NLOHMANN_JSON_VERSION)
        unset(_nlohmann_json_version)
    endif()

endif()

unset(_nlohmann_json_tree)

include(FindPackageHandleStandardArgs)

find_package_handle_standard_args(
    nlohmann_json
    REQUIRED_VARS NLOHMANN_JSON_DIR
    VERSION_VAR NLOHMANN_JSON_VERSION
)
