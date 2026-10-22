# -----------------------------------------------------------------------------
# Findimplot.cmake - ImPlot, plots for Dear ImGui, as the static library
# implot::implot
#
#   list(APPEND CMAKE_MODULE_PATH "<the folder of this file>")
#   find_package(implot REQUIRED)
#   target_link_libraries(my_app PRIVATE implot::implot)    # brings imgui::imgui
#
# ImPlot needs ImGui: a project that has imgui::imgui already uses it,
# otherwise Findimgui.cmake beside this file finds or fetches it. ImPlot has no
# CMake build of its own: this file makes the library from its sources
# (implot*.cpp, with the demo). Include: <implot.h>.
#
# Where it comes from:
#
#   1. IMPLOT_ROOT_DIR, when it is set (-DIMPLOT_ROOT_DIR=<dir>, a variable of
#      the calling project, or the environment variable of that name) and holds
#      the library: either an install prefix with implot-config.cmake (vcpkg,
#      Conan) or its source tree.
#   2. Otherwise FetchContent clones IMPLOT_GIT_REPOSITORY at IMPLOT_GIT_TAG
#      once into IMPLOT_SOURCE_DIR and builds it as part of the calling
#      project. Later configures, in any build folder, use that copy as it is;
#      delete the folder to fetch again (e.g. for another tag).
#
# Variables, all optional, read when find_package() is called:
#
#   IMPLOT_ROOT_DIR         the library you have (see 1.)
#   IMPLOT_GIT_REPOSITORY   default: https://github.com/epezent/implot.git
#   IMPLOT_GIT_TAG          tag or branch; default: v1.0
#   IMPLOT_SOURCE_DIR       where the clone goes;
#                           default: ../extern/implot beside this file
#
# The repository can be on any git server (a mirror, offline): it is cloned
# without submodules.
#
# Result:
#
#   implot_FOUND            TRUE when the target exists
#   IMPLOT_DIR              the library in use: its package folder (install
#                           prefix) or its source tree
#   IMPLOT_VERSION          its version
#
# A project that already has implot::implot uses it as it is.
# -----------------------------------------------------------------------------

if(TARGET implot::implot)
    set(implot_FOUND TRUE)
    return()
endif()

if(NOT TARGET imgui::imgui)
    find_package(imgui QUIET)
endif()

set(IMPLOT_ROOT_DIR "$ENV{IMPLOT_ROOT_DIR}"
    CACHE PATH "ImPlot to use: an install prefix or a source tree (empty: fetch it with git)")

if(NOT IMPLOT_GIT_REPOSITORY)
    set(IMPLOT_GIT_REPOSITORY "https://github.com/epezent/implot.git")
endif()

if(NOT IMPLOT_GIT_TAG)
    set(IMPLOT_GIT_TAG "v1.0")
endif()

if(NOT IMPLOT_SOURCE_DIR)
    set(IMPLOT_SOURCE_DIR "${CMAKE_CURRENT_LIST_DIR}/../extern/implot")
endif()

# Full paths with forward slashes, however they were given (C:\libs\implot).
get_filename_component(IMPLOT_SOURCE_DIR "${IMPLOT_SOURCE_DIR}" ABSOLUTE)
if(IMPLOT_ROOT_DIR)
    get_filename_component(IMPLOT_ROOT_DIR "${IMPLOT_ROOT_DIR}" ABSOLUTE)
endif()

set(IMPLOT_DIR "")
set(IMPLOT_VERSION "")

# -----------------------------------------------------------------------------
# 1. IMPLOT_ROOT_DIR
# -----------------------------------------------------------------------------

set(_implot_tree "")            # a source tree to build, instead of the clone

if(IMPLOT_ROOT_DIR)

    find_package(implot CONFIG QUIET PATHS "${IMPLOT_ROOT_DIR}" NO_DEFAULT_PATH)

    if(implot_FOUND)
        set(IMPLOT_DIR "${implot_DIR}")
        set(IMPLOT_VERSION "${implot_VERSION}")
    elseif(EXISTS "${IMPLOT_ROOT_DIR}/implot.cpp")
        set(_implot_tree "${IMPLOT_ROOT_DIR}")
    else()
        message(WARNING
            "implot: IMPLOT_ROOT_DIR is ${IMPLOT_ROOT_DIR}, which holds neither an installed "
            "ImPlot (implot-config.cmake) nor its sources. Using the fetched ImPlot in "
            "${IMPLOT_SOURCE_DIR} instead.")
    endif()

endif()

# -----------------------------------------------------------------------------
# 2. FetchContent, from the git repository; the library is made here (only
#    with ImGui)
# -----------------------------------------------------------------------------

if(NOT IMPLOT_DIR AND TARGET imgui::imgui)

    include(FetchContent)

    # A source tree that is there already (IMPLOT_ROOT_DIR, or fetched before,
    # possibly by another build folder): use it as it is.
    if(_implot_tree)
        set(FETCHCONTENT_SOURCE_DIR_IMPLOT "${_implot_tree}")
    elseif(EXISTS "${IMPLOT_SOURCE_DIR}/implot.cpp")
        set(FETCHCONTENT_SOURCE_DIR_IMPLOT "${IMPLOT_SOURCE_DIR}")
    elseif(NOT implot_FIND_QUIETLY)
        message(STATUS "implot: fetching ${IMPLOT_GIT_TAG} from ${IMPLOT_GIT_REPOSITORY} "
                       "into ${IMPLOT_SOURCE_DIR} (set IMPLOT_ROOT_DIR to use one you have)")
    endif()

    FetchContent_Declare(
        implot
        GIT_REPOSITORY "${IMPLOT_GIT_REPOSITORY}"
        GIT_TAG "${IMPLOT_GIT_TAG}"
        GIT_SHALLOW TRUE
        GIT_SUBMODULES ""
        SOURCE_DIR "${IMPLOT_SOURCE_DIR}"
    )

    # No CMakeLists.txt in the tree: this only clones it.
    FetchContent_MakeAvailable(implot)

    unset(FETCHCONTENT_SOURCE_DIR_IMPLOT)

    if(EXISTS "${implot_SOURCE_DIR}/implot.cpp")
        set(IMPLOT_DIR "${implot_SOURCE_DIR}")

        add_library(
            implot STATIC
            "${IMPLOT_DIR}/implot.cpp"
            "${IMPLOT_DIR}/implot_demo.cpp"
            "${IMPLOT_DIR}/implot_items.cpp"
        )
        add_library(implot::implot ALIAS implot)

        target_include_directories(implot PUBLIC "$<BUILD_INTERFACE:${IMPLOT_DIR}>")
        target_link_libraries(implot PUBLIC imgui::imgui)

        # Static, but may be linked into a shared library.
        set_target_properties(implot PROPERTIES POSITION_INDEPENDENT_CODE ON)

        # The version is the one the header itself declares.
        file(STRINGS "${IMPLOT_DIR}/implot.h" _implot_version
             REGEX "#define IMPLOT_VERSION +\"")
        string(REGEX MATCHALL "[0-9]+" _implot_version "${_implot_version}")
        list(JOIN _implot_version "." IMPLOT_VERSION)
        unset(_implot_version)
    endif()

endif()

unset(_implot_tree)

include(FindPackageHandleStandardArgs)

find_package_handle_standard_args(
    implot
    REQUIRED_VARS IMPLOT_DIR
    VERSION_VAR IMPLOT_VERSION
    REASON_FAILURE_MESSAGE "implot needs ImGui (Findimgui.cmake, or the target imgui::imgui)"
)
