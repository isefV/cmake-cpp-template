# mylib with libzmq (the C API): requests and replies between two threads.

find_package(ZeroMQ REQUIRED)

add_executable(
    mylib_zeromq
    main.cpp
)

target_link_libraries(
    mylib_zeromq
    PRIVATE
        mylib::mylib
        libzmq                                          # or libzmq-static
)

if(MYLIB_BUILD_TESTS)
    add_test(
        NAME mylib.zeromq
        COMMAND mylib_zeromq
    )
endif()
