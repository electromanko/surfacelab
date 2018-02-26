require 'beaglebone'
include Beaglebone

GPIOPin.new(:P8_8, :OUT).digital_write(:HIGH)
p9_31 = GPIOPin.new(:P9_31, :OUT)
p9_28 = GPIOPin.new(:P9_28, :OUT)
p8_7 = GPIOPin.new(:P8_7, :OUT)

p8_7.digital_write(:HIGH)
sleep 1
p8_7.digital_write(:LOW)

for i in 0..100000
    p9_31.digital_write(:LOW)
    p9_28.digital_write(:LOW)
    sleep 0.1
    p9_31.digital_write(:HIGH)
    p9_28.digital_write(:HIGH)
    sleep 0.1
    puts i
end
gets