cmake_minimum_required(VERSION 3.19)

project(fatcubin)

enable_language(CUDA)
find_package(CUDAToolkit REQUIRED)

add_library(${PROJECT_NAME} SHARED "src/${PROJECT_NAME}.cu" "src/elf.c")
set_property(TARGET ${PROJECT_NAME} PROPERTY CUDA_ARCHITECTURES OFF)
target_include_directories(${PROJECT_NAME} PUBLIC include)
target_link_libraries(${PROJECT_NAME} CUDA::cuda_driver)

add_executable(${PROJECT_NAME}_test "src/test/${PROJECT_NAME}.cu")
target_link_libraries(${PROJECT_NAME}_test ${PROJECT_NAME})

add_executable(sample_app "src/sample_app/sample_app.cu")

