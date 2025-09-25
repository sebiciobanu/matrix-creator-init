#!/bin/bash
# This script uses gpioset to control GPIO pins.
# Assumes libgpiod-utils is installed and gpiochip0 corresponds to BCM pins.

LOG_FILE=/tmp/sam3-program.log

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

function reset_mcu() {
  # Exporting GPIO 18 and setting direction is not needed with gpioset.
  gpioset gpiochip0 18=1
  gpioset gpiochip0 18=0
  gpioset gpiochip0 18=1
}

function try_program() {
  reset_mcu
  sleep 0.1

  RES=$(openocd -f cfg/sam3s_rpi_sysfs.cfg 2>&1 | tee ${LOG_FILE} | grep wrote | wc -l)
  echo $RES
  
  sleep 0.5
  reset_mcu  
}

function enable_program() {
  gpioset gpiochip0 19=1
  gpioset gpiochip0 20=0
  gpioset gpiochip0 20=1
  echo "Running the program instead of the bootloader" 
}

function check_firmware() {
 COMPARE_VERSION=$(diff <(./firmware_info | grep MCU) <(cat mcu_firmware.version)|wc -l)

 if [ "$COMPARE_VERSION" == "0" ];then
  echo 1
 else #failed
  echo 0 
 fi
}

# Exporting GPIOs is not needed with libgpiod.
# Direction setting is also handled by gpioset for output pins.

super_reset 
reset_mcu

CHECK=$(check_firmware)
if [ "$CHECK" == "1" ]
then
  reset_mcu
  enable_program
  echo "SAM3 MCU was programmed before. Not programming it again."
  exit 0
fi
enable_program # This was missing in the original script logic if CHECK failed. Added for consistency.
count=0
while [  $count -lt 30 ]; do
  TEST=$(try_program)
  if [ "$TEST" == "1" ];then
        CHECK=$(check_firmware)
        if [ "$CHECK" == "1" ];then
          echo "****  SAM3 MCU programmed!"
          reset_mcu # ensure MCU is in a good state after programming
          exit 0
        fi
   fi
  let count=count+1
done
echo "**** Could not program SAM3 MCU, you must be check the logfile ${LOG_FILE}"
exit 1
