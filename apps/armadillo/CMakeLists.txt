# mylib with Armadillo: matrices and vectors.

find_package(Armadillo REQUIRED)

add_executable(
    mylib_armadillo
    main.cpp
)

target_link_libraries(
    mylib_armadillo
    PRIVATE
        mylib::mylib
        armadillo
)

if(MYLIB_BUILD_TESTS)
    add_test(
        NAME mylib.armadillo
        COMMAND mylib_armadillo
    )
endif()
