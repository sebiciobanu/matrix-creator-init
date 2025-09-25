#!/bin/bash
# This script uses gpioset to control GPIO pins.
# Assumes libgpiod-utils is installed and gpiochip0 corresponds to BCM pins.

CHECKSUM=2f58e62dcd36cf18490c80435fb29992
LOG_FILE=/tmp/em358-program.log

function super_reset()
{
  # gpio19 - EM358 nBOOTMODE (active low)
  # gpio18 - mcu power
  # gpio20 - EM_NRST - EM3588 RESET (active low)
  # gpio23 - EM3588 POWER ENABLE

  # Set out mode for pins 18, 19, 20, 23 is implicit with gpioset.
  # Pins 4, 17, 22, 27 were set to 'in', this is their default state or managed by gpioget if read.
  # No explicit gpioget needed here as these pins are not read in this script.

  #Power EM_358 OFF 
  gpioset gpiochip0 18=1
  gpioset gpiochip0 19=1
  gpioset gpiochip0 20=1
  gpioset gpiochip0 23=0
  sleep 0.5

  #Power ON
  gpioset gpiochip0 23=1
  sleep 0.5

  gpioset gpiochip0 18=0
  gpioset gpiochip0 19=0
  gpioset gpiochip0 20=0

  sleep 0.5
  gpioset gpiochip0 18=1
  gpioset gpiochip0 20=1

  sleep 0.5
  gpioset gpiochip0 19=1
}

function check_flash_status() {
  openocd -f  cfg/em358_check.cfg > /dev/null 2>  /dev/null 
}

function try_program() {
  sleep 0.5
  RES=$(openocd -f  cfg/em358.cfg 2>&1 | tee -a ${LOG_FILE} | grep wrote | wc -l)
  echo $RES
}

function enable_program() {
  gpioset gpiochip0 19=1
  gpioset gpiochip0 20=0
  gpioset gpiochip0 20=1

  echo "*** Running the program instead of the bootloader" 
}

# Exporting GPIOs is not needed with libgpiod.
# Direction setting is also handled by gpioset for output pins.

super_reset

check_flash_status
SUM=$(md5sum /tmp/em358_dump | awk  '{printf $1}')


if [ "${CHECKSUM}" = "${SUM}" ]
then 
    enable_program
    echo "EM358 MCU was programmed before. Not programming it again."
    exit 0
fi

super_reset

count=0
while [  $count -lt 10 ]; do
  TEST=$(try_program)

  if [ "$TEST" == "1" ];
  then
	echo "****  EM358 MCU programmed!"
        break
   fi
  let count=count+1
done
enable_program
