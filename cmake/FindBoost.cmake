# -----------------------------------------------------------------------------
# FindBoost.cmake - Boost, as the targets Boost::headers and Boost::<component>
#
#   list(APPEND CMAKE_MODULE_PATH "<the folder of this file>")
#   find_package(Boost REQUIRED COMPONENTS filesystem program_options)
#   target_link_libraries(my_app PRIVATE Boost::filesystem Boost::program_options)
#
# The COMPONENTS are the Boost libraries to build, by their Boost names; Boost
# adds the libraries they depend on itself. Without COMPONENTS all of Boost is
# configured, which takes long.
#
# Where Boost comes from:
#
#   1. BOOST_ROOT_DIR, when it is set (-DBOOST_ROOT_DIR=<dir>, a variable of
#      the calling project, or the environment variable of that name) and holds
#      a Boost: either an install prefix (the folder with lib/cmake/Boost-<ver>)
#      or a source tree of the Boost superproject (CMakeLists.txt, tools/cmake
#      and libs/).
#   2. Otherwise FetchContent clones BOOST_GIT_REPOSITORY at BOOST_GIT_TAG, with
#      its submodules, once into BOOST_SOURCE_DIR and builds the COMPONENTS as
#      part of the calling project. Later configures, in any build folder, use
#      that copy as it is; delete the folder to fetch again (e.g. for another
#      tag).
#
# Variables, all optional, read when find_package() is called:
#
#   BOOST_ROOT_DIR          a Boost you have (see 1.)
#   BOOST_GIT_REPOSITORY    default: https://github.com/boostorg/boost.git
#   BOOST_GIT_TAG           tag or branch; default: boost-1.92.0
#   BOOST_GIT_SUBMODULES    the submodules to clone, for less to download, e.g.
#                           "tools/cmake;libs/headers;libs/config;libs/assert"
#                           (tools/cmake, libs/headers, the COMPONENTS and all
#                           they depend on); default: all of them
#   BOOST_SOURCE_DIR        where the clone goes;
#                           default: ../extern/boost beside this file
#
# Another git server (a mirror, offline): set BOOST_GIT_REPOSITORY to its copy
# of boostorg/boost. Boost names its submodules relative to that repository
# (url = ../system.git), so git clones them from the same server: keep them
# beside it under their own names (system.git, config.git, ...). A repository
# that holds the whole Boost tree and has no submodules works as it is.
#
# Result:
#
#   Boost_FOUND             TRUE when Boost::headers and the Boost::<component>
#                           targets exist
#   Boost_<component>_FOUND TRUE for each component that has its target
#   BOOST_DIR               the Boost in use: its package folder (install
#                           prefix) or its source tree
#   BOOST_VERSION           its version
#
# A project that already has these targets is used as it is. In a project that
# lists the folder of this file in CMAKE_MODULE_PATH, this file is used instead
# of CMake's own FindBoost module (deprecated since CMake 3.30, CMP0167).
# -----------------------------------------------------------------------------

set(Boost_FOUND TRUE)
foreach(_boost_component IN LISTS Boost_FIND_COMPONENTS ITEMS headers)
    if(NOT TARGET Boost::${_boost_component})
        set(Boost_FOUND FALSE)
    endif()
endforeach()

if(Boost_FOUND)
    foreach(_boost_component IN LISTS Boost_FIND_COMPONENTS)
        set(Boost_${_boost_component}_FOUND TRUE)
    endforeach()
    unset(_boost_component)
    return()
endif()

set(BOOST_ROOT_DIR "$ENV{BOOST_ROOT_DIR}"
    CACHE PATH "Boost to use: an install prefix or a source tree (empty: fetch it with git)")

if(NOT BOOST_GIT_REPOSITORY)
    set(BOOST_GIT_REPOSITORY "https://github.com/boostorg/boost.git")
endif()

if(NOT BOOST_GIT_TAG)
    set(BOOST_GIT_TAG "boost-1.92.0")
endif()

if(NOT BOOST_SOURCE_DIR)
    set(BOOST_SOURCE_DIR "${CMAKE_CURRENT_LIST_DIR}/../extern/boost")
endif()

# Full paths with forward slashes, however they were given (C:\libs\boost).
get_filename_component(BOOST_SOURCE_DIR "${BOOST_SOURCE_DIR}" ABSOLUTE)
if(BOOST_ROOT_DIR)
    get_filename_component(BOOST_ROOT_DIR "${BOOST_ROOT_DIR}" ABSOLUTE)
endif()

set(BOOST_DIR "")
set(BOOST_VERSION "")

# -----------------------------------------------------------------------------
# 1. BOOST_ROOT_DIR
# -----------------------------------------------------------------------------

set(_boost_tree "")             # a source tree to build, instead of the clone

if(BOOST_ROOT_DIR)

    find_package(Boost CONFIG QUIET COMPONENTS ${Boost_FIND_COMPONENTS}
                 PATHS "${BOOST_ROOT_DIR}" NO_DEFAULT_PATH)

    if(Boost_FOUND)
        set(BOOST_DIR "${Boost_DIR}")
        set(BOOST_VERSION "${Boost_VERSION}")
    elseif(EXISTS "${BOOST_ROOT_DIR}/tools/cmake/include/BoostRoot.cmake")
        set(_boost_tree "${BOOST_ROOT_DIR}")
    else()
        message(WARNING
            "Boost: BOOST_ROOT_DIR is ${BOOST_ROOT_DIR}, which holds neither an installed "
            "Boost (lib/cmake/Boost-<version>, with the requested components) nor its "
            "sources. Using the fetched Boost in ${BOOST_SOURCE_DIR} instead.")
    endif()

endif()

# -----------------------------------------------------------------------------
# 2. FetchContent, from the git repository
# -----------------------------------------------------------------------------

if(NOT BOOST_DIR)

    include(FetchContent)

    # A source tree that is there already (BOOST_ROOT_DIR, or fetched before,
    # possibly by another build folder): use it as it is.
    if(_boost_tree)
        set(FETCHCONTENT_SOURCE_DIR_BOOST "${_boost_tree}")
    elseif(EXISTS "${BOOST_SOURCE_DIR}/tools/cmake/include/BoostRoot.cmake")
        set(FETCHCONTENT_SOURCE_DIR_BOOST "${BOOST_SOURCE_DIR}")
    elseif(NOT Boost_FIND_QUIETLY)
        message(STATUS "Boost: fetching ${BOOST_GIT_TAG} from ${BOOST_GIT_REPOSITORY} "
                       "into ${BOOST_SOURCE_DIR} (set BOOST_ROOT_DIR to use one you have)")
    endif()

    # All submodules, unless only some are asked for.
    set(_boost_submodules "")
    if(BOOST_GIT_SUBMODULES)
        set(_boost_submodules GIT_SUBMODULES ${BOOST_GIT_SUBMODULES})
    endif()

    # Boost's own setting: build only the COMPONENTS and what they need. As
    # part of another project Boost adds no tests and no install rules.
    set(BOOST_INCLUDE_LIBRARIES ${Boost_FIND_COMPONENTS})

    FetchContent_Declare(
        boost
        GIT_REPOSITORY "${BOOST_GIT_REPOSITORY}"
        GIT_TAG "${BOOST_GIT_TAG}"
        GIT_SHALLOW TRUE
        GIT_CONFIG submodule.fetchJobs=8    # clone the submodules in parallel
        ${_boost_submodules}
        SOURCE_DIR "${BOOST_SOURCE_DIR}"
    )

    FetchContent_MakeAvailable(boost)

    unset(FETCHCONTENT_SOURCE_DIR_BOOST)
    unset(BOOST_INCLUDE_LIBRARIES)
    unset(_boost_submodules)

    if(TARGET Boost::headers)
        set(BOOST_DIR "${boost_SOURCE_DIR}")

        # The version is the one the source tree itself declares.
        file(STRINGS "${boost_SOURCE_DIR}/CMakeLists.txt" _boost_version
             REGEX "project\\(Boost VERSION [0-9.]+")
        if(_boost_version MATCHES "([0-9]+(\\.[0-9]+)+)")
            set(BOOST_VERSION "${CMAKE_MATCH_1}")
        endif()
        unset(_boost_version)
    endif()

endif()

unset(_boost_tree)

foreach(_boost_component IN LISTS Boost_FIND_COMPONENTS)
    if(TARGET Boost::${_boost_component})
        set(Boost_${_boost_component}_FOUND TRUE)
    else()
        set(Boost_${_boost_component}_FOUND FALSE)
    endif()
endforeach()
unset(_boost_component)

include(FindPackageHandleStandardArgs)

find_package_handle_standard_args(
    Boost
    REQUIRED_VARS BOOST_DIR
    VERSION_VAR BOOST_VERSION
    HANDLE_COMPONENTS
)
