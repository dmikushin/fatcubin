cmake_minimum_required(VERSION 3.9)

project(mriera)

enable_language(CUDA)

add_executable(${PROJECT_NAME} "src/mriera.cu" "src/elf.c")
set_property(TARGET ${PROJECT_NAME} PROPERTY CUDA_ARCHITECTURES OFF)
target_include_directories(${PROJECT_NAME} PRIVATE include)
target_link_libraries(${PROJECT_NAME} cuda)

