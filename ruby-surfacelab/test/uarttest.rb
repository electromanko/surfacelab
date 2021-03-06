require_relative '../lib/surfacelab/surfacelab'
require 'beaglebone'
include Beaglebone
include Surfacelab

callback = lambda { |uart, data, count| puts "#{data}" }
callback2 = lambda { |uart, data, count| puts "#{uart}:#{data}" }

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

uart_data = sl.devhash[:UART][:MCU_UART_DSL_DATA]
uart_data.run_on_each_line(callback2)

=begin
uart_conf = sl.devhash[:UART][:MCU_UART_DSL_CONFIG]
uart_conf.run_on_each_line(callback)
sleep 0.1
uart_conf.writeln("\r\n")
uart_conf.writeln("config show\r\n")                             
#uart4.each_line { |line| puts line }
gets
=end

puts "LINKUP: #{sl.devhash[:GPIO][:DSL_LINKUP].digital_read}"

sl.devhash[:GPIO][:DSL_MODE0].digital_write(:HIGH)
sl.devhash[:GPIO][:DSL_MODE1].digital_write(:HIGH)

for i in 0..10000
    uart_data.write("byte: #{i}\n")
    sleep 2
end

# Run the following block 5 times
10.times do
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

