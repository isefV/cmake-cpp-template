# mylib with ImPlot: a window (GLFW, OpenGL 3) with a live plot.
# --frames <n> closes it after n frames (0: when the window is closed).
#
# imgui::imgui, with its GLFW and OpenGL 3 backends, comes from
# apps/CMakeLists.txt.

find_package(implot REQUIRED)

add_executable(
    mylib_implot
    main.cpp
)

target_link_libraries(
    mylib_implot
    PRIVATE
        mylib::mylib
        implot::implot
)
