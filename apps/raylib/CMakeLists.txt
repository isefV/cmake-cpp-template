# mylib with raylib: a window with a bouncing ball. --frames <n> closes it
# after n frames (0: when the window is closed).

find_package(raylib REQUIRED)

add_executable(
    mylib_raylib
    main.cpp
)

target_link_libraries(
    mylib_raylib
    PRIVATE
        mylib::mylib
        raylib
)
