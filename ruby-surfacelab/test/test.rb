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
puts sl.devhash

uart4 = sl.devhash[:UART][:MCU_UART_DSL_CONFIG]
uart4.run_on_each_line(callback)
sleep 0.1
uart4.writeln("\r\n")
uart4.writeln("config show\r\n")
#uart4.each_line { |line| puts line }
gets

spi1 = sl.devhash[:SPI][:DSL_SPI_DATA]
raw = spi1.xfer([ 0x41, 0x42].pack("C*"))
p raw.unpack("C*")
raw = spi1.xfer([ 0x41, 0x43].pack("C*"))
p raw.unpack("C*")

# Run the following block 5 times
5.times do
  # Iterate over each LED
  [:USR0,:USR1,:USR2,:USR3].each do |led|
    # Turn on the LED
    sl.devhash[:GPIO][led].digital_write(:HIGH)
    # Delay 0.25 seconds
    sleep 0.05
    # Turn off the LED
    sl.devhash[:GPIO][led].digital_write(:LOW)

  end
end