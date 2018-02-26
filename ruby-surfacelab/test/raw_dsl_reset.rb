require 'beaglebone'
include Beaglebone

GPIOPin.new(:P8_8, :OUT).digital_write(:LOW)
p8_7= GPIOPin.new(:P8_7, :OUT)
p8_7.digital_write(:HIGH)
sleep 1
p8_7.digital_write(:LOW)