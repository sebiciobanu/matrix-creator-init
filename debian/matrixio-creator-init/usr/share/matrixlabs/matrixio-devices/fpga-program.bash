#!/bin/bash
# This script uses gpioset to control GPIO pins.
# Assumes gpiod is installed and gpiochip0 corresponds to BCM pins.

cd /usr/share/matrixlabs/matrixio-devices

if grep -q "Pi 4" /sys/firmware/devicetree/base/model 2>/dev/null; then
  P4DETECT="true"
fi

function reset_voice(){
  # Set GPIO26 to 1 (output high)
  gpioset gpiochip0 26=1
  # Set GPIO26 to 0 (output low)
  gpioset gpiochip0 26=0
  # Set GPIO26 to 1 (output high)
  gpioset gpiochip0 26=1
  sleep 2
}

function reset_creator(){
  # Set GPIO18 to 1 (output high)
  gpioset gpiochip0 18=1
  # Set GPIO18 to 0 (output low)
  gpioset gpiochip0 18=0
  # Set GPIO18 to 1 (output high)
  gpioset gpiochip0 18=1
}

function try_program_creator() {
  if [ -n "$P4DETECT" ]; 
  then 
	  CABLE=gpiod_creator
  else
	  CABLE=matrix_creator
  fi

  reset_creator
  sleep 0.1
  # The $CABLE variable is set to 'sysfsgpio_creator' on Raspberry Pi 4 and later,
  # or 'matrix_creator' on older Raspberry Pi models.
  # The 'sysfsgpio_creator' driver for xc3sprog likely depends on the sysfs GPIO interface.
  # For this to work on Raspbian Bookworm or newer, which have deprecated direct sysfs GPIO access,
  # the 'dtoverlay=gpio-legacy' parameter may need to be added to /boot/firmware/config.txt
  # (or /boot/config.txt on older OS versions) and the system rebooted.
  # The 'matrix_creator' driver's compatibility with Bookworm also depends on how
  # matrixio-xc3sprog handles GPIO access for that specific driver (it might use wiringPi or sysfs).
  xc3sprog -c $CABLE blob/system_creator.bit -p 1
}

function try_program_voice() {
  if [ -n "$P4DETECT" ]; 
  then 
	  CABLE=gpiod_voice
  else
	  CABLE=matrix_voice
  fi

  reset_voice
  sleep 0.1
  # The $CABLE variable is set to 'sysfsgpio_voice' on Raspberry Pi 4 and later,
  # or 'matrix_voice' on older Raspberry Pi models.
  # The 'sysfsgpio_voice' driver for xc3sprog likely depends on the sysfs GPIO interface.
  # For this to work on Raspbian Bookworm or newer, which have deprecated direct sysfs GPIO access,
  # the 'dtoverlay=gpio-legacy' parameter may need to be added to /boot/firmware/config.txt
  # (or /boot/config.txt on older OS versions) and the system rebooted.
  # The 'matrix_voice' driver's compatibility with Bookworm also depends on how
  # matrixio-xc3sprog handles GPIO access for that specific driver (it might use wiringPi or sysfs).
  xc3sprog -c $CABLE blob/bscan_spi_s6lx9_ftg256.bit
  sleep 0.1
  xc3sprog -c $CABLE -I blob/system_voice.bit
}

function update_voice(){
count=0
while [  $count -lt 5 ]; do 
  try_program_voice
  if [ $? -eq 0 ];then
        echo "****  MATRIX Voice FPGA Software has been updated!"
	reset_voice
        exit 0
   fi
  let count=count+1
done
}

function program_creator(){
count=0
while [  $count -lt 5 ]; do
  try_program_creator
  if [ $? -eq 0 ];then
        echo "**** MATRIX Creator FPGA has been programmed!"
	./fpga_info
        exit 0
   fi
  let count=count+1
done
}

function check_voice() {
  reset_voice
  COMPARE_VERSION=$(diff <(./fpga_info | grep FPGA) <(cat voice.version)|wc -l)
  if [ "$COMPARE_VERSION" == "0" ];then
     echo "*** MATRIX Voice has a updated firmware"
     exit 0
   else #failed
     update_voice
  fi
}

program_creator # If MATRIX Creator has not been detected, try with MATRIX Voice steps
check_voice

echo "**** Could not program FPGA"
exit 1
