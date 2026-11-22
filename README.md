# distributed-kv
Distributed Key-Value Store in C++20 using Raft

## Build and test

With a C++20 compiler and CMake 3.20 or newer, run from the repository root.

```sh
cmake -S . -B build -DCMAKE_BUILD_TYPE=Debug
cmake --build build
ctest --test-dir build --output-on-failure
```

The M1 exercise runs as `./build/read_first_line <file>` on Linux.
