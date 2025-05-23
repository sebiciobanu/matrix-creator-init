cmake_minimum_required(VERSION 2.8)

# Root CMakeLists.txt for the matrixio-creator-init package.
# This project builds utility applications that interact with MATRIX Creator/Voice hardware.
#
# External Dependencies:
# - libmatrixio-creator-hal: The Hardware Abstraction Layer for MATRIX devices.
#   This library must be pre-installed on the system and be compatible with
#   Raspbian Bookworm. Compatibility may involve ensuring that its own
#   dependencies (historically including wiringpi) are met on Bookworm,
#   potentially by using a version of HAL updated for libgpiod, or by
#   configuring the system to support legacy GPIO access if required by HAL.
#
# The C++ applications are defined in the cpp/ subdirectory.

# Add -Wall and -Wextra. Also,
# treat C/C++ warnings as errors if -DADM_FATAL_WARNINGS=ON.
# include (cmake/FatalWarnings.cmake) # Optional: uncomment to enable
# ADM_EXTRA_WARNINGS()                # Optional: uncomment to enable

add_subdirectory(cpp)


