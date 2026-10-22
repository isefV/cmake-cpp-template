# -----------------------------------------------------------------------------
# Findraylib.cmake - raylib, a library for games and graphics programs, as the
# target raylib
#
#   list(APPEND CMAKE_MODULE_PATH "<the folder of this file>")
#   find_package(raylib REQUIRED)
#   target_link_libraries(my_app PRIVATE raylib)
#
# raylib brings its own GLFW; a project that found GLFW before (Findglfw3.cmake)
# makes raylib use that one. On Linux it needs the X11 development packages
# (Debian/Ubuntu: libx11-dev libxrandr-dev libxinerama-dev libxcursor-dev
# libxi-dev libgl-dev). raylib is static unless BUILD_SHARED_LIBS is ON.
#
# Where it comes from:
#
#   1. RAYLIB_ROOT_DIR, when it is set (-DRAYLIB_ROOT_DIR=<dir>, a variable of
#      the calling project, or the environment variable of that name) and holds
#      the library: either an install prefix (the folder with lib/cmake/raylib)
#      or its source tree.
#   2. Otherwise FetchContent clones RAYLIB_GIT_REPOSITORY at RAYLIB_GIT_TAG
#      once into RAYLIB_SOURCE_DIR and builds it as part of the calling
#      project. Later configures, in any build folder, use that copy as it is;
#      delete the folder to fetch again (e.g. for another tag).
#
# Variables, all optional, read when find_package() is called:
#
#   RAYLIB_ROOT_DIR         the library you have (see 1.)
#   RAYLIB_GIT_REPOSITORY   default: https://github.com/raysan5/raylib.git
#   RAYLIB_GIT_TAG          tag or branch; default: 6.2
#   RAYLIB_SOURCE_DIR       where the clone goes;
#                           default: ../extern/raylib beside this file
#
# The repository can be on any git server (a mirror, offline): it is cloned
# without submodules.
#
# Result:
#
#   raylib_FOUND            TRUE when the target exists
#   RAYLIB_DIR              the library in use: its package folder (install
#                           prefix) or its source tree
#   RAYLIB_VERSION          its version
#
# A project that already has the target raylib uses it as it is.
# -----------------------------------------------------------------------------

if(TARGET raylib)
    set(raylib_FOUND TRUE)
    return()
endif()

set(RAYLIB_ROOT_DIR "$ENV{RAYLIB_ROOT_DIR}"
    CACHE PATH "raylib to use: an install prefix or a source tree (empty: fetch it with git)")

if(NOT RAYLIB_GIT_REPOSITORY)
    set(RAYLIB_GIT_REPOSITORY "https://github.com/raysan5/raylib.git")
endif()

if(NOT RAYLIB_GIT_TAG)
    set(RAYLIB_GIT_TAG "6.2")
endif()

if(NOT RAYLIB_SOURCE_DIR)
    set(RAYLIB_SOURCE_DIR "${CMAKE_CURRENT_LIST_DIR}/../extern/raylib")
endif()

# Full paths with forward slashes, however they were given (C:\libs\raylib).
get_filename_component(RAYLIB_SOURCE_DIR "${RAYLIB_SOURCE_DIR}" ABSOLUTE)
if(RAYLIB_ROOT_DIR)
    get_filename_component(RAYLIB_ROOT_DIR "${RAYLIB_ROOT_DIR}" ABSOLUTE)
endif()

set(RAYLIB_DIR "")
set(RAYLIB_VERSION "")

# -----------------------------------------------------------------------------
# 1. RAYLIB_ROOT_DIR
# -----------------------------------------------------------------------------

set(_raylib_tree "")            # a source tree to build, instead of the clone

if(RAYLIB_ROOT_DIR)

    find_package(raylib CONFIG QUIET PATHS "${RAYLIB_ROOT_DIR}" NO_DEFAULT_PATH)

    if(raylib_FOUND AND TARGET raylib)
        set(RAYLIB_DIR "${raylib_DIR}")
        set(RAYLIB_VERSION "${raylib_VERSION}")
    elseif(EXISTS "${RAYLIB_ROOT_DIR}/src/raylib.h")
        set(_raylib_tree "${RAYLIB_ROOT_DIR}")
    else()
        message(WARNING
            "raylib: RAYLIB_ROOT_DIR is ${RAYLIB_ROOT_DIR}, which holds neither an installed "
            "raylib (lib/cmake/raylib) nor its sources. Using the fetched raylib in "
            "${RAYLIB_SOURCE_DIR} instead.")
    endif()

endif()

# -----------------------------------------------------------------------------
# 2. FetchContent, from the git repository
# -----------------------------------------------------------------------------

if(NOT RAYLIB_DIR)

    include(FetchContent)

    # A source tree that is there already (RAYLIB_ROOT_DIR, or fetched before,
    # possibly by another build folder): use it as it is.
    if(_raylib_tree)
        set(FETCHCONTENT_SOURCE_DIR_RAYLIB "${_raylib_tree}")
    elseif(EXISTS "${RAYLIB_SOURCE_DIR}/src/raylib.h")
        set(FETCHCONTENT_SOURCE_DIR_RAYLIB "${RAYLIB_SOURCE_DIR}")
    elseif(NOT raylib_FIND_QUIETLY)
        message(STATUS "raylib: fetching ${RAYLIB_GIT_TAG} from ${RAYLIB_GIT_REPOSITORY} "
                       "into ${RAYLIB_SOURCE_DIR} (set RAYLIB_ROOT_DIR to use one you have)")
    endif()

    # As part of another project raylib builds no examples (BUILD_EXAMPLES).

    FetchContent_Declare(
        raylib
        GIT_REPOSITORY "${RAYLIB_GIT_REPOSITORY}"
        GIT_TAG "${RAYLIB_GIT_TAG}"
        GIT_SHALLOW TRUE
        GIT_SUBMODULES ""
        SOURCE_DIR "${RAYLIB_SOURCE_DIR}"
    )

    FetchContent_MakeAvailable(raylib)

    unset(FETCHCONTENT_SOURCE_DIR_RAYLIB)

    if(TARGET raylib)
        set(RAYLIB_DIR "${raylib_SOURCE_DIR}")

        # The version is the one the header itself declares.
        file(STRINGS "${raylib_SOURCE_DIR}/src/raylib.h" _raylib_version
             REGEX "#define RAYLIB_VERSION +\"")
        string(REGEX MATCHALL "[0-9]+" _raylib_version "${_raylib_version}")
        list(JOIN _raylib_version "." RAYLIB_VERSION)
        unset(_raylib_version)
    endif()

endif()

unset(_raylib_tree)

include(FindPackageHandleStandardArgs)

find_package_handle_standard_args(
    raylib
    REQUIRED_VARS RAYLIB_DIR
    VERSION_VAR RAYLIB_VERSION
)
