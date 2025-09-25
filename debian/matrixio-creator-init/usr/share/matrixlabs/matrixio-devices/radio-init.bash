#!/bin/bash
# This script uses gpioset to control GPIO pins.
# Assumes libgpiod-utils is installed and gpiochip0 corresponds to BCM pins.

# Exporting GPIOs 21 and 16 and setting direction is not needed with gpioset.
# gpioset handles this implicitly when setting the value.

gpioset gpiochip0 16=0
gpioset gpiochip0 21=1
