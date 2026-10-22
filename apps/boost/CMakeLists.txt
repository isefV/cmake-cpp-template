# mylib with Boost: command-line options read by Boost.ProgramOptions.

find_package(Boost 1.85 REQUIRED COMPONENTS program_options)

add_executable(
    mylib_boost
    main.cpp
)

target_link_libraries(
    mylib_boost
    PRIVATE
        mylib::mylib
        Boost::program_options
)

if(MYLIB_BUILD_TESTS)
    add_test(
        NAME mylib.boost
        COMMAND mylib_boost --from 1 --to 10
    )
endif()
