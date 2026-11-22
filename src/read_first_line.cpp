#include <cstdlib>
#include <fstream>
#include <iostream>
#include <string>

int main(int argc, char* argv[]) {
    if (argc != 2) {
        std::cerr << "Usage: read_first_line <file>\n";
        return EXIT_FAILURE;
    }

    std::ifstream input{argv[1]};
    if (!input.is_open()) {
        std::cerr << "Could not open file: " << argv[1] << '\n';
        return EXIT_FAILURE;
    }

    std::string line;
    if (!std::getline(input, line)) {
        std::cerr << "Could not read a line from file: " << argv[1] << '\n';
        return EXIT_FAILURE;
    }

    std::cout << line << '\n';
    return EXIT_SUCCESS;
}
