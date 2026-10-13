# A small program that uses the library.

add_executable(
    mylib_app
    main.cpp
)

target_link_libraries(
    mylib_app
    PRIVATE
        mylib::mylib
)

# A short run in CTest checks that the program starts and ends cleanly.
if(MYLIB_BUILD_TESTS)
    add_test(
        NAME mylib.app
        COMMAND mylib_app
    )
endif()
