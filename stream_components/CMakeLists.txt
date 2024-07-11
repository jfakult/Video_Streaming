cmake_minimum_required(VERSION 3.10)
project(libCameraHelper)

find_package(PkgConfig REQUIRED)
pkg_check_modules(LIBCAMERA REQUIRED libcamera)

add_executable(libCameraHelper libCameraHelper.cpp)
target_include_directories(libCameraHelper PRIVATE ${LIBCAMERA_INCLUDE_DIRS})
target_link_libraries(libCameraHelper ${LIBCAMERA_LIBRARIES})

