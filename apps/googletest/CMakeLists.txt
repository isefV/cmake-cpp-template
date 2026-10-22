# mylib with GoogleTest and GoogleMock: fixtures, parameterized tests and
# matchers. Each test is registered with CTest (when MYLIB_BUILD_TESTS is ON).

find_package(GoogleTest REQUIRED)

add_executable(
    mylib_googletest
    main.cpp
)

target_link_libraries(
    mylib_googletest
    PRIVATE
        mylib::mylib
        GTest::gmock_main
)

if(MYLIB_BUILD_TESTS)
    include(GoogleTest)

    gtest_discover_tests(
        mylib_googletest
        TEST_PREFIX "mylib.googletest."
        DISCOVERY_MODE PRE_TEST
    )
endif()
