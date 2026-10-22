# mylib with cppzmq (the C++ API of ZeroMQ): a publisher and a subscriber.

find_package(cppzmq REQUIRED)

add_executable(
    mylib_cppzmq
    main.cpp
)

target_link_libraries(
    mylib_cppzmq
    PRIVATE
        mylib::mylib
        cppzmq                                          # or cppzmq-static
)

if(MYLIB_BUILD_TESTS)
    add_test(
        NAME mylib.cppzmq
        COMMAND mylib_cppzmq
    )
endif()
