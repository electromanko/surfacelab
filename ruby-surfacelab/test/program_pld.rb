require_relative '../lib/surfacelab/surfacelab'
require 'beaglebone'
include Beaglebone
include Surfacelab

callback = lambda { |uart, data, count| puts "#{data}" }

sl = SurfacelabDevice.new
puts sl.devhash
sl.devhash[:GPIO][:DSL_MASTER].digital_write(:LOW)
sl.devhash[:GPIO][:DSL_RESET].digital_write(:LOW)

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



uart4 = sl.devhash[:UART][:MCU_UART_DSL_CONFIG]
uart4.run_on_each_line(callback)
sleep 0.1
uart4.writeln("\r")
uart4.writeln("config show\r")
gets
uart4.writeln("\r")
uart4.writeln("eeprom\r")
puts "U SHURE????"
gets
aFile = File.new("/home/debian/MODEM/setreg_pause_link0/shdsl_b1_gf37_eeprom_disk.hex", "r+")
cntr=0
kcntr =0
if aFile
   aFile.each_byte do |ch|
     uart4.write(ch)
     if cntr > 1000
         cntr=0
         kcntr+=1
         puts "Sended #{kcntr} kB\r"
     else
         cntr+=1
     end
     sleep 0.001
   end
else
   puts "Unable to open file!"
end
gets


