# mylib with Boost.SML: a state machine for a coin-operated turnstile.

find_package(sml REQUIRED)

add_executable(
    mylib_sml
    main.cpp
)

target_link_libraries(
    mylib_sml
    PRIVATE
        mylib::mylib
        sml::sml
)

if(MYLIB_BUILD_TESTS)
    add_test(
        NAME mylib.sml
        COMMAND mylib_sml
    )
endif()
