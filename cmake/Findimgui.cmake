# -----------------------------------------------------------------------------
# Findimgui.cmake - Dear ImGui, as the static library imgui::imgui
#
#   list(APPEND CMAKE_MODULE_PATH "<the folder of this file>")
#   set(IMGUI_BACKENDS glfw opengl3)                    # optional, see below
#   find_package(imgui REQUIRED)
#   target_link_libraries(imgui PUBLIC glfw OpenGL::GL) # what the backends use
#   target_link_libraries(my_app PRIVATE imgui::imgui)
#
# ImGui has no CMake build of its own: this file makes the library from its
# sources (imgui*.cpp, with the demo window) and the backends named in
# IMGUI_BACKENDS (backends/imgui_impl_<name>.cpp). A backend needs its own
# libraries (GLFW, SDL, OpenGL, DirectX, ...): link them to the target imgui as
# above. Includes: <imgui.h>, <imgui_impl_<name>.h>.
#
# Where it comes from:
#
#   1. IMGUI_ROOT_DIR, when it is set (-DIMGUI_ROOT_DIR=<dir>, a variable of the
#      calling project, or the environment variable of that name) and holds the
#      library: either an install prefix with imgui-config.cmake (vcpkg, Conan)
#      or its source tree.
#   2. Otherwise FetchContent clones IMGUI_GIT_REPOSITORY at IMGUI_GIT_TAG once
#      into IMGUI_SOURCE_DIR and builds it as part of the calling project.
#      Later configures, in any build folder, use that copy as it is; delete
#      the folder to fetch again (e.g. for another tag).
#
# Variables, all optional, read when find_package() is called:
#
#   IMGUI_ROOT_DIR          the library you have (see 1.)
#   IMGUI_GIT_REPOSITORY    default: https://github.com/ocornut/imgui.git
#   IMGUI_GIT_TAG           tag or branch; default: v1.93.0
#                           (docking branch: v1.93.0-docking)
#   IMGUI_SOURCE_DIR        where the clone goes;
#                           default: ../extern/imgui beside this file
#   IMGUI_BACKENDS          backends to build in, e.g. "glfw;opengl3" or
#                           "win32;dx11"; default: none
#
# The repository can be on any git server (a mirror, offline): it is cloned
# without submodules.
#
# Result:
#
#   imgui_FOUND             TRUE when the target exists
#   IMGUI_DIR               the library in use: its package folder (install
#                           prefix) or its source tree
#   IMGUI_VERSION           its version
#
# A project that already has imgui::imgui uses it as it is.
# -----------------------------------------------------------------------------

if(TARGET imgui::imgui)
    set(imgui_FOUND TRUE)
    return()
endif()

set(IMGUI_ROOT_DIR "$ENV{IMGUI_ROOT_DIR}"
    CACHE PATH "ImGui to use: an install prefix or a source tree (empty: fetch it with git)")

if(NOT IMGUI_GIT_REPOSITORY)
    set(IMGUI_GIT_REPOSITORY "https://github.com/ocornut/imgui.git")
endif()

if(NOT IMGUI_GIT_TAG)
    set(IMGUI_GIT_TAG "v1.93.0")
endif()

if(NOT IMGUI_SOURCE_DIR)
    set(IMGUI_SOURCE_DIR "${CMAKE_CURRENT_LIST_DIR}/../extern/imgui")
endif()

# Full paths with forward slashes, however they were given (C:\libs\imgui).
get_filename_component(IMGUI_SOURCE_DIR "${IMGUI_SOURCE_DIR}" ABSOLUTE)
if(IMGUI_ROOT_DIR)
    get_filename_component(IMGUI_ROOT_DIR "${IMGUI_ROOT_DIR}" ABSOLUTE)
endif()

set(IMGUI_DIR "")
set(IMGUI_VERSION "")

# -----------------------------------------------------------------------------
# 1. IMGUI_ROOT_DIR
# -----------------------------------------------------------------------------

set(_imgui_tree "")             # a source tree to build, instead of the clone

if(IMGUI_ROOT_DIR)

    find_package(imgui CONFIG QUIET PATHS "${IMGUI_ROOT_DIR}" NO_DEFAULT_PATH)

    if(imgui_FOUND)
        set(IMGUI_DIR "${imgui_DIR}")
        set(IMGUI_VERSION "${imgui_VERSION}")
    elseif(EXISTS "${IMGUI_ROOT_DIR}/imgui.cpp")
        set(_imgui_tree "${IMGUI_ROOT_DIR}")
    else()
        message(WARNING
            "imgui: IMGUI_ROOT_DIR is ${IMGUI_ROOT_DIR}, which holds neither an installed "
            "ImGui (imgui-config.cmake) nor its sources. Using the fetched ImGui in "
            "${IMGUI_SOURCE_DIR} instead.")
    endif()

endif()

# -----------------------------------------------------------------------------
# 2. FetchContent, from the git repository; the library is made here
# -----------------------------------------------------------------------------

if(NOT IMGUI_DIR)

    include(FetchContent)

    # A source tree that is there already (IMGUI_ROOT_DIR, or fetched before,
    # possibly by another build folder): use it as it is.
    if(_imgui_tree)
        set(FETCHCONTENT_SOURCE_DIR_IMGUI "${_imgui_tree}")
    elseif(EXISTS "${IMGUI_SOURCE_DIR}/imgui.cpp")
        set(FETCHCONTENT_SOURCE_DIR_IMGUI "${IMGUI_SOURCE_DIR}")
    elseif(NOT imgui_FIND_QUIETLY)
        message(STATUS "imgui: fetching ${IMGUI_GIT_TAG} from ${IMGUI_GIT_REPOSITORY} "
                       "into ${IMGUI_SOURCE_DIR} (set IMGUI_ROOT_DIR to use one you have)")
    endif()

    FetchContent_Declare(
        imgui
        GIT_REPOSITORY "${IMGUI_GIT_REPOSITORY}"
        GIT_TAG "${IMGUI_GIT_TAG}"
        GIT_SHALLOW TRUE
        GIT_SUBMODULES ""
        SOURCE_DIR "${IMGUI_SOURCE_DIR}"
    )

    # No CMakeLists.txt in the tree: this only clones it.
    FetchContent_MakeAvailable(imgui)

    unset(FETCHCONTENT_SOURCE_DIR_IMGUI)

    if(EXISTS "${imgui_SOURCE_DIR}/imgui.cpp")
        set(IMGUI_DIR "${imgui_SOURCE_DIR}")

        add_library(
            imgui STATIC
            "${IMGUI_DIR}/imgui.cpp"
            "${IMGUI_DIR}/imgui_demo.cpp"
            "${IMGUI_DIR}/imgui_draw.cpp"
            "${IMGUI_DIR}/imgui_tables.cpp"
            "${IMGUI_DIR}/imgui_widgets.cpp"
        )
        add_library(imgui::imgui ALIAS imgui)

        foreach(_imgui_backend IN LISTS IMGUI_BACKENDS)
            target_sources(imgui PRIVATE "${IMGUI_DIR}/backends/imgui_impl_${_imgui_backend}.cpp")
        endforeach()
        unset(_imgui_backend)

        target_include_directories(
            imgui
            PUBLIC
                "$<BUILD_INTERFACE:${IMGUI_DIR}>"
                "$<BUILD_INTERFACE:${IMGUI_DIR}/backends>"
        )

        # Static, but may be linked into a shared library.
        set_target_properties(imgui PROPERTIES POSITION_INDEPENDENT_CODE ON)

        # The version is the one the header itself declares.
        file(STRINGS "${IMGUI_DIR}/imgui.h" _imgui_version
             REGEX "#define IMGUI_VERSION +\"")
        string(REGEX MATCHALL "[0-9]+" _imgui_version "${_imgui_version}")
        list(JOIN _imgui_version "." IMGUI_VERSION)
        unset(_imgui_version)
    endif()

endif()

unset(_imgui_tree)

include(FindPackageHandleStandardArgs)

find_package_handle_standard_args(
    imgui
    REQUIRED_VARS IMGUI_DIR
    VERSION_VAR IMGUI_VERSION
)
