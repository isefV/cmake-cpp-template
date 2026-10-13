# Tests, written with GoogleTest (cmake/FindGoogleTest.cmake). Each TEST() is
# registered with CTest as its own test: ctest --test-dir <build> -R Counter

add_executable(
    mylib_tests
    mylib_test.cpp
)

target_link_libraries(
    mylib_tests
    PRIVATE
        mylib::mylib
        GTest::gtest_main
)

include(GoogleTest)

# PRE_TEST: the tests are listed when ctest runs, not while building, so a
# shared mylib only has to be next to the test program by then.
gtest_discover_tests(
    mylib_tests
    DISCOVERY_MODE PRE_TEST
)
