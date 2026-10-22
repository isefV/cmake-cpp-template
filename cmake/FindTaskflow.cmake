# -----------------------------------------------------------------------------
# FindTaskflow.cmake - Taskflow, task-parallel programming (header-only), as the
# target Taskflow::Taskflow
#
#   list(APPEND CMAKE_MODULE_PATH "<the folder of this file>")
#   find_package(Taskflow REQUIRED)
#   target_link_libraries(my_app PRIVATE Taskflow::Taskflow)
#
# Where it comes from:
#
#   1. TASKFLOW_ROOT_DIR, when it is set (-DTASKFLOW_ROOT_DIR=<dir>, a variable
#      of the calling project, or the environment variable of that name) and
#      holds the library: either an install prefix (the folder with
#      lib/cmake/Taskflow) or its source tree.
#   2. Otherwise FetchContent clones TASKFLOW_GIT_REPOSITORY at TASKFLOW_GIT_TAG
#      once into TASKFLOW_SOURCE_DIR and adds it to the calling project. Later
#      configures, in any build folder, use that copy as it is; delete the
#      folder to fetch again (e.g. for another tag).
#
# Variables, all optional, read when find_package() is called:
#
#   TASKFLOW_ROOT_DIR       the library you have (see 1.)
#   TASKFLOW_GIT_REPOSITORY default: https://github.com/taskflow/taskflow.git
#   TASKFLOW_GIT_TAG        tag or branch; default: v4.1.0
#   TASKFLOW_SOURCE_DIR     where the clone goes;
#                           default: ../extern/taskflow beside this file
#
# The repository can be on any git server (a mirror, offline): it is cloned
# without submodules.
#
# Result:
#
#   Taskflow_FOUND          TRUE when the target exists
#   TASKFLOW_DIR            the library in use: its package folder (install
#                           prefix) or its source tree
#   TASKFLOW_VERSION        its version
#
# A project that already has Taskflow::Taskflow uses it as it is.
# -----------------------------------------------------------------------------

if(TARGET Taskflow::Taskflow)
    set(Taskflow_FOUND TRUE)
    return()
endif()

set(TASKFLOW_ROOT_DIR "$ENV{TASKFLOW_ROOT_DIR}"
    CACHE PATH "Taskflow to use: an install prefix or a source tree (empty: fetch it with git)")

if(NOT TASKFLOW_GIT_REPOSITORY)
    set(TASKFLOW_GIT_REPOSITORY "https://github.com/taskflow/taskflow.git")
endif()

if(NOT TASKFLOW_GIT_TAG)
    set(TASKFLOW_GIT_TAG "v4.1.0")
endif()

if(NOT TASKFLOW_SOURCE_DIR)
    set(TASKFLOW_SOURCE_DIR "${CMAKE_CURRENT_LIST_DIR}/../extern/taskflow")
endif()

# Full paths with forward slashes, however they were given (C:\libs\taskflow).
get_filename_component(TASKFLOW_SOURCE_DIR "${TASKFLOW_SOURCE_DIR}" ABSOLUTE)
if(TASKFLOW_ROOT_DIR)
    get_filename_component(TASKFLOW_ROOT_DIR "${TASKFLOW_ROOT_DIR}" ABSOLUTE)
endif()

set(TASKFLOW_DIR "")
set(TASKFLOW_VERSION "")

# -----------------------------------------------------------------------------
# 1. TASKFLOW_ROOT_DIR
# -----------------------------------------------------------------------------

set(_taskflow_tree "")          # a source tree to use, instead of the clone

if(TASKFLOW_ROOT_DIR)

    find_package(Taskflow CONFIG QUIET PATHS "${TASKFLOW_ROOT_DIR}" NO_DEFAULT_PATH)

    if(Taskflow_FOUND)
        set(TASKFLOW_DIR "${Taskflow_DIR}")
        set(TASKFLOW_VERSION "${Taskflow_VERSION}")
    elseif(EXISTS "${TASKFLOW_ROOT_DIR}/TaskflowConfig.cmake.in")
        set(_taskflow_tree "${TASKFLOW_ROOT_DIR}")
    else()
        message(WARNING
            "Taskflow: TASKFLOW_ROOT_DIR is ${TASKFLOW_ROOT_DIR}, which holds neither an "
            "installed Taskflow (lib/cmake/Taskflow) nor its sources. Using the fetched "
            "Taskflow in ${TASKFLOW_SOURCE_DIR} instead.")
    endif()

endif()

# -----------------------------------------------------------------------------
# 2. FetchContent, from the git repository
# -----------------------------------------------------------------------------

if(NOT TASKFLOW_DIR)

    include(FetchContent)

    # A source tree that is there already (TASKFLOW_ROOT_DIR, or fetched
    # before, possibly by another build folder): use it as it is.
    if(_taskflow_tree)
        set(FETCHCONTENT_SOURCE_DIR_TASKFLOW "${_taskflow_tree}")
    elseif(EXISTS "${TASKFLOW_SOURCE_DIR}/TaskflowConfig.cmake.in")
        set(FETCHCONTENT_SOURCE_DIR_TASKFLOW "${TASKFLOW_SOURCE_DIR}")
    elseif(NOT Taskflow_FIND_QUIETLY)
        message(STATUS "Taskflow: fetching ${TASKFLOW_GIT_TAG} from ${TASKFLOW_GIT_REPOSITORY} "
                       "into ${TASKFLOW_SOURCE_DIR} (set TASKFLOW_ROOT_DIR to use one you have)")
    endif()

    # Taskflow's own settings: no tests and no examples.
    set(TF_BUILD_TESTS OFF)
    set(TF_BUILD_EXAMPLES OFF)

    FetchContent_Declare(
        taskflow
        GIT_REPOSITORY "${TASKFLOW_GIT_REPOSITORY}"
        GIT_TAG "${TASKFLOW_GIT_TAG}"
        GIT_SHALLOW TRUE
        GIT_SUBMODULES ""
        SOURCE_DIR "${TASKFLOW_SOURCE_DIR}"
    )

    FetchContent_MakeAvailable(taskflow)

    unset(FETCHCONTENT_SOURCE_DIR_TASKFLOW)
    unset(TF_BUILD_TESTS)
    unset(TF_BUILD_EXAMPLES)

    if(TARGET Taskflow::Taskflow)
        set(TASKFLOW_DIR "${taskflow_SOURCE_DIR}")

        # The version is the one the source tree itself declares.
        file(STRINGS "${taskflow_SOURCE_DIR}/CMakeLists.txt" _taskflow_version
             REGEX "project\\(Taskflow VERSION [0-9.]+")
        string(REGEX MATCHALL "[0-9]+" _taskflow_version "${_taskflow_version}")
        list(JOIN _taskflow_version "." TASKFLOW_VERSION)
        unset(_taskflow_version)
    endif()

endif()

unset(_taskflow_tree)

include(FindPackageHandleStandardArgs)

find_package_handle_standard_args(
    Taskflow
    REQUIRED_VARS TASKFLOW_DIR
    VERSION_VAR TASKFLOW_VERSION
)
