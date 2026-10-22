# Example programs. Each app is a directory with its own target.
# apps/consumer is a separate CMake project and isn't added here.
#
# apps/app uses only mylib. Each of the others uses mylib together with one
# library, which it finds with find_package() (cmake/Find<Name>.cmake). They
# are off by default: the first configure with one on clones its library into
# extern/.

add_subdirectory(app)

option(MYLIB_BUILD_APP_BOOST         "Build apps/boost (Boost.ProgramOptions)"            OFF)
option(MYLIB_BUILD_APP_NLOHMANN_JSON "Build apps/nlohmann_json (JSON for Modern C++)"     OFF)
option(MYLIB_BUILD_APP_SML           "Build apps/sml (Boost.SML state machine)"           OFF)
option(MYLIB_BUILD_APP_TASKFLOW      "Build apps/taskflow (Taskflow task graph)"          OFF)
option(MYLIB_BUILD_APP_RAYLIB        "Build apps/raylib (raylib window)"                  OFF)
option(MYLIB_BUILD_APP_ZEROMQ        "Build apps/zeromq (libzmq C API)"                   OFF)
option(MYLIB_BUILD_APP_CPPZMQ        "Build apps/cppzmq (ZeroMQ C++ API)"                 OFF)
option(MYLIB_BUILD_APP_ARMADILLO     "Build apps/armadillo (Armadillo linear algebra)"    OFF)
option(MYLIB_BUILD_APP_IMGUI         "Build apps/imgui (Dear ImGui with GLFW, OpenGL 3)"  OFF)
option(MYLIB_BUILD_APP_IMPLOT        "Build apps/implot (ImPlot with GLFW, OpenGL 3)"     OFF)
option(MYLIB_BUILD_APP_GOOGLETEST    "Build apps/googletest (GoogleTest and GoogleMock)"  OFF)

# ImGui with its GLFW and OpenGL 3 backends, used by apps/imgui and apps/implot.
if(MYLIB_BUILD_APP_IMGUI OR MYLIB_BUILD_APP_IMPLOT)
    set(IMGUI_BACKENDS glfw opengl3)
    find_package(glfw3 REQUIRED)                            # glfw
    find_package(OpenGL REQUIRED)                           # OpenGL::GL
    find_package(imgui REQUIRED)                            # imgui::imgui

    # The backends' libraries, when Findimgui.cmake made the target.
    if(TARGET imgui)
        target_link_libraries(imgui PUBLIC glfw OpenGL::GL)
    endif()
endif()

foreach(app IN ITEMS boost nlohmann_json sml taskflow raylib zeromq cppzmq armadillo imgui implot googletest)
    string(TOUPPER "${app}" APP)
    if(MYLIB_BUILD_APP_${APP})
        add_subdirectory(${app})
    endif()
endforeach()
