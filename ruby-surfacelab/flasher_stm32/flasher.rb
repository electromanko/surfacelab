require_relative '../lib/surfacelab/surfacelab'
require 'beaglebone'
include Beaglebone
include Surfacelab

callback = lambda { |uart, data, count| puts "#{data}" }

#p8_43 = GPIOPin.new(:P8_43, :IN, :PULLUP, :FAST)

# Initialize pin P9_12 in OUTPUT mode
#p8_44 = GPIOPin.new(:P8_44, :OUT)
#p8_44.digital_write(:LOW)
#sleep 0.1
# Run the following block 5 times
#callback2 = lambda { |pin,edge,count| puts "[#{count}] #{pin} #{edge}"}
#p8_43.run_on_edge(callback2, :BOTH)
#sleep 0.1
#10.times do

 #   p8_44.digital_write(:HIGH)
    # Delay 0.25 seconds
#    sleep 0.1
    # Turn off the LED
#    p8_44.digital_write(:LOW)
#    sleep 0.1
#end

sl = SurfacelabDevice.new
callback = lambda { |uart, data, count| puts "#{data}" }
puts sl.devhash
uart4 = sl.devhash[:UART][:MCU_UART_DEPTH_BOOT]
uart4.run_on_each_char(callback)

#BOOT MODE
sl.devhash[:GPIO][:MCU_RESET].digital_write(:HIGH)
sl.devhash[:GPIO][:MCU_BOOT].digital_write(:HIGH)
sleep 0.5
sl.devhash[:GPIO][:MCU_RESET].digital_write(:LOW)
sleep 0.5
for i in 0..100
    uart4.write([0x7f].pack("C*"))
    sleep 0.1
end
sleep 2

#uart4.run_on_each_line(callback)

uart4.write([ 0x02, 0xfd].pack("C*"))
#uart4.each_line { |line| puts line }
gets
sl.devhash[:GPIO][:MCU_BOOT].digital_write(:LOW)

