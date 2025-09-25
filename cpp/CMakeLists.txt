# CMake build file for firmware_info and fpga_info applications.
# These applications are part of the matrixio-creator-init package and
# provide information about the MATRIX Creator/Voice hardware.
#
# Dependencies:
# 1. libmatrixio-creator-hal: This is the Hardware Abstraction Layer provided
#    by MATRIX Labs. It must be installed on the system and be compatible
#    with Raspbian Bookworm.
# 2. PkgConfig: Used to find libmatrixio-creator-hal.
# 3. Threads: Standard threads library.
#
# Note on libmatrixio-creator-hal and wiringpi:
# Historically, libmatrixio-creator-hal has had a dependency on the wiringpi
# library for GPIO access. WiringPi is deprecated and may not work out-of-the-box
# on Raspbian Bookworm. Users might need to:
#   a) Ensure a version of wiringpi compatible with their system is installed
#      (e.g., by using the gpio-legacy overlay if sysfs access is still required
#      by wiringpi or HAL components).
#   b) Or, ensure they have a version of libmatrixio-creator-hal that has been
#      updated to no longer rely on wiringpi (e.g., uses libgpiod).
#
# The build process for matrixio-creator-init does not build libmatrixio-creator-hal;
# it is expected to be pre-installed.

project(matrixio_creator_init_utils C CXX) # Renamed project for clarity
cmake_minimum_required(VERSION 2.8)

add_definitions(-std=c++11)

# Enable extra warnings. Not needed by default.
# include (../cmake/FatalWarnings.cmake)
# ADM_EXTRA_WARNINGS()

find_package(PkgConfig REQUIRED)

# Use pkg-config to find libmatrixio-creator-hal
# The package name might be 'matrix-creator-hal' or 'libmatrixio-creator-hal'
# depending on how the HAL library's .pc file is named.
# Using 'libmatrixio-creator-hal' as it's commonly used for library .pc files.
set(MATRIX_HAL_INCLUDE_DIRS /usr/include)
set(MATRIX_HAL_LIBRARIES matrix_creator_hal)

# Include HAL directories
if(MATRIX_HAL_INCLUDE_DIRS)
  include_directories(${MATRIX_HAL_INCLUDE_DIRS})
endif()

# gflags is searched for but not directly used by firmware_info or fpga_info.
# It might be a dependency for other HAL components or planned for future use.
FIND_LIBRARY(GFLAGS_LIB NAMES gflags)
message(STATUS "gflags found =>" "${GFLAGS_LIB}") 

find_package(Threads REQUIRED)

add_executable(firmware_info firmware_info.cpp)
  set_property(TARGET firmware_info PROPERTY CXX_STANDARD 11)
  target_link_libraries(firmware_info 
    ${MATRIX_HAL_LIBRARIES}
    ${CMAKE_THREAD_LIBS_INIT}
  )

add_executable(fpga_info fpga_info.cpp)
  set_property(TARGET fpga_info PROPERTY CXX_STANDARD 11)
  target_link_libraries(fpga_info 
    ${MATRIX_HAL_LIBRARIES}
    ${CMAKE_THREAD_LIBS_INIT}
  )


