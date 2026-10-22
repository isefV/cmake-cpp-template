# -----------------------------------------------------------------------------
# Findglfw3.cmake - GLFW, windows and input for OpenGL/Vulkan, as the target glfw
#
#   list(APPEND CMAKE_MODULE_PATH "<the folder of this file>")
#   find_package(glfw3 REQUIRED)
#   target_link_libraries(my_app PRIVATE glfw)
#
# On Linux GLFW needs the X11 and Wayland development packages (Debian/Ubuntu:
# libx11-dev libxrandr-dev libxinerama-dev libxcursor-dev libxi-dev
# libwayland-dev libxkbcommon-dev). GLFW is static unless BUILD_SHARED_LIBS
# is ON.
#
# Where it comes from:
#
#   1. GLFW3_ROOT_DIR, when it is set (-DGLFW3_ROOT_DIR=<dir>, a variable of
#      the calling project, or the environment variable of that name) and holds
#      the library: either an install prefix (the folder with lib/cmake/glfw3)
#      or its source tree.
#   2. Otherwise FetchContent clones GLFW3_GIT_REPOSITORY at GLFW3_GIT_TAG once
#      into GLFW3_SOURCE_DIR and builds it as part of the calling project.
#      Later configures, in any build folder, use that copy as it is; delete
#      the folder to fetch again (e.g. for another tag).
#
# Variables, all optional, read when find_package() is called:
#
#   GLFW3_ROOT_DIR          the library you have (see 1.)
#   GLFW3_GIT_REPOSITORY    default: https://github.com/glfw/glfw.git
#   GLFW3_GIT_TAG           tag or branch; default: 3.5.1
#   GLFW3_SOURCE_DIR        where the clone goes;
#                           default: ../extern/glfw beside this file
#
# The repository can be on any git server (a mirror, offline): it is cloned
# without submodules. GLFW's own CMake adds install rules, so installing the
# calling project installs GLFW too.
#
# Result:
#
#   glfw3_FOUND             TRUE when the target exists
#   GLFW3_DIR               the library in use: its package folder (install
#                           prefix) or its source tree
#   GLFW3_VERSION           its version
#
# A project that already has the target glfw uses it as it is.
# -----------------------------------------------------------------------------

if(TARGET glfw)
    set(glfw3_FOUND TRUE)
    return()
endif()

set(GLFW3_ROOT_DIR "$ENV{GLFW3_ROOT_DIR}"
    CACHE PATH "GLFW to use: an install prefix or a source tree (empty: fetch it with git)")

if(NOT GLFW3_GIT_REPOSITORY)
    set(GLFW3_GIT_REPOSITORY "https://github.com/glfw/glfw.git")
endif()

if(NOT GLFW3_GIT_TAG)
    set(GLFW3_GIT_TAG "3.5.1")
endif()

if(NOT GLFW3_SOURCE_DIR)
    set(GLFW3_SOURCE_DIR "${CMAKE_CURRENT_LIST_DIR}/../extern/glfw")
endif()

# Full paths with forward slashes, however they were given (C:\libs\glfw).
get_filename_component(GLFW3_SOURCE_DIR "${GLFW3_SOURCE_DIR}" ABSOLUTE)
if(GLFW3_ROOT_DIR)
    get_filename_component(GLFW3_ROOT_DIR "${GLFW3_ROOT_DIR}" ABSOLUTE)
endif()

set(GLFW3_DIR "")
set(GLFW3_VERSION "")

# -----------------------------------------------------------------------------
# 1. GLFW3_ROOT_DIR
# -----------------------------------------------------------------------------

set(_glfw3_tree "")             # a source tree to build, instead of the clone

if(GLFW3_ROOT_DIR)

    find_package(glfw3 CONFIG QUIET PATHS "${GLFW3_ROOT_DIR}" NO_DEFAULT_PATH)

    if(glfw3_FOUND)
        set(GLFW3_DIR "${glfw3_DIR}")
        set(GLFW3_VERSION "${glfw3_VERSION}")
    elseif(EXISTS "${GLFW3_ROOT_DIR}/src/init.c")
        set(_glfw3_tree "${GLFW3_ROOT_DIR}")
    else()
        message(WARNING
            "glfw3: GLFW3_ROOT_DIR is ${GLFW3_ROOT_DIR}, which holds neither an installed "
            "GLFW (lib/cmake/glfw3) nor its sources. Using the fetched GLFW in "
            "${GLFW3_SOURCE_DIR} instead.")
    endif()

endif()

# -----------------------------------------------------------------------------
# 2. FetchContent, from the git repository
# -----------------------------------------------------------------------------

if(NOT GLFW3_DIR)

    include(FetchContent)

    # A source tree that is there already (GLFW3_ROOT_DIR, or fetched before,
    # possibly by another build folder): use it as it is.
    if(_glfw3_tree)
        set(FETCHCONTENT_SOURCE_DIR_GLFW "${_glfw3_tree}")
    elseif(EXISTS "${GLFW3_SOURCE_DIR}/src/init.c")
        set(FETCHCONTENT_SOURCE_DIR_GLFW "${GLFW3_SOURCE_DIR}")
    elseif(NOT glfw3_FIND_QUIETLY)
        message(STATUS "glfw3: fetching ${GLFW3_GIT_TAG} from ${GLFW3_GIT_REPOSITORY} "
                       "into ${GLFW3_SOURCE_DIR} (set GLFW3_ROOT_DIR to use one you have)")
    endif()

    # GLFW's own settings: no docs. As part of another project it builds no
    # examples and no tests. Its install rules stay on, and it is a normal
    # library: raylib uses this GLFW when both are in one project, and
    # raylib's install rules need GLFW's. Set here, not taken from the cache,
    # where raylib's own GLFW leaves GLFW_INSTALL=OFF, GLFW_LIBRARY_TYPE=OBJECT.
    set(GLFW_BUILD_DOCS OFF)
    set(GLFW_INSTALL ON)
    set(GLFW_LIBRARY_TYPE "")

    FetchContent_Declare(
        glfw
        GIT_REPOSITORY "${GLFW3_GIT_REPOSITORY}"
        GIT_TAG "${GLFW3_GIT_TAG}"
        GIT_SHALLOW TRUE
        GIT_SUBMODULES ""
        SOURCE_DIR "${GLFW3_SOURCE_DIR}"
    )

    FetchContent_MakeAvailable(glfw)

    unset(FETCHCONTENT_SOURCE_DIR_GLFW)
    unset(GLFW_BUILD_DOCS)
    unset(GLFW_INSTALL)
    unset(GLFW_LIBRARY_TYPE)

    if(TARGET glfw)
        set(GLFW3_DIR "${glfw_SOURCE_DIR}")

        # The version is the one the header itself declares.
        file(STRINGS "${glfw_SOURCE_DIR}/include/GLFW/glfw3.h" _glfw3_version
             REGEX "#define GLFW_VERSION_(MAJOR|MINOR|REVISION) ")
        string(REGEX MATCHALL "[0-9]+" _glfw3_version "${_glfw3_version}")
        list(JOIN _glfw3_version "." GLFW3_VERSION)
        unset(_glfw3_version)
    endif()

endif()

unset(_glfw3_tree)

include(FindPackageHandleStandardArgs)

find_package_handle_standard_args(
    glfw3
    REQUIRED_VARS GLFW3_DIR
    VERSION_VAR GLFW3_VERSION
)
