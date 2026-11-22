cmake_minimum_required(VERSION 3.20)
project(distributed_kv LANGUAGES CXX)

add_executable(read_first_line src/read_first_line.cpp)
set_target_properties(read_first_line PROPERTIES
    CXX_STANDARD 20
    CXX_STANDARD_REQUIRED ON
    CXX_EXTENSIONS OFF
)

include(CTest)
if(BUILD_TESTING)
    add_test(NAME read_first_line
        COMMAND "${CMAKE_COMMAND}"
            "-DPROGRAM=$<TARGET_FILE:read_first_line>"
            -P "${CMAKE_CURRENT_SOURCE_DIR}/tests/read_first_line.cmake")
endif()
