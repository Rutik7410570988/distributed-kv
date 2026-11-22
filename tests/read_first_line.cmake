cmake_minimum_required(VERSION 3.20)

function(check_read label expected_result expected_output expected_error)
    execute_process(
        COMMAND "${PROGRAM}" ${ARGN}
        RESULT_VARIABLE result
        OUTPUT_VARIABLE output
        ERROR_VARIABLE error
    )
    if(NOT result MATCHES "${expected_result}"
       OR NOT output STREQUAL expected_output
       OR NOT error MATCHES "${expected_error}")
        message(FATAL_ERROR
            "${label}: unexpected exit status (${result}), stdout (${output}), or stderr (${error})")
    endif()
endfunction()

set(fixture_dir "${CMAKE_CURRENT_BINARY_DIR}/read_first_line_fixtures")
file(MAKE_DIRECTORY "${fixture_dir}")
file(WRITE "${fixture_dir}/two lines.txt" "first line\nsecond line\n")
file(WRITE "${fixture_dir}/empty.txt" "")

check_read("two lines" "^0$" "first line\n" "^$" "${fixture_dir}/two lines.txt")
check_read("missing file" "^[1-9][0-9]*$" "" "^Could not open file:" "${fixture_dir}/missing.txt")
check_read("empty file" "^[1-9][0-9]*$" "" "^Could not read a line from file:" "${fixture_dir}/empty.txt")
check_read("no argument" "^[1-9][0-9]*$" "" "^Usage:")
