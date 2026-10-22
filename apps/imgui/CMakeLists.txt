# mylib with Dear ImGui: a window (GLFW, OpenGL 3) with buttons and a slider.
# --frames <n> closes it after n frames (0: when the window is closed).
#
# imgui::imgui, with its GLFW and OpenGL 3 backends, comes from
# apps/CMakeLists.txt.

add_executable(
    mylib_imgui
    main.cpp
)

target_link_libraries(
    mylib_imgui
    PRIVATE
        mylib::mylib
        imgui::imgui
)
