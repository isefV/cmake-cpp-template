# mylib with Taskflow: a sum split into tasks that run in parallel.

find_package(Taskflow REQUIRED)

add_executable(
    mylib_taskflow
    main.cpp
)

target_link_libraries(
    mylib_taskflow
    PRIVATE
        mylib::mylib
        Taskflow::Taskflow
)

if(MYLIB_BUILD_TESTS)
    add_test(
        NAME mylib.taskflow
        COMMAND mylib_taskflow
    )
endif()
