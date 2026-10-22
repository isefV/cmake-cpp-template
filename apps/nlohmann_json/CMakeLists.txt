# mylib with nlohmann_json: a result written as JSON and read back.

find_package(nlohmann_json 3.11 REQUIRED)

add_executable(
    mylib_nlohmann_json
    main.cpp
)

target_link_libraries(
    mylib_nlohmann_json
    PRIVATE
        mylib::mylib
        nlohmann_json::nlohmann_json
)

if(MYLIB_BUILD_TESTS)
    add_test(
        NAME mylib.nlohmann_json
        COMMAND mylib_nlohmann_json
    )
endif()
