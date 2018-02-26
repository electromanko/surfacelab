require_relative '../lib/surfacelab/surfacelab'
require 'beaglebone'
include Beaglebone
include Surfacelab

sl = SurfacelabDevice.new
sl.devhash[:GPIO][:DSL_MASTER].digital_write(:LOW)
sl.devhash[:GPIO][:DSL_RESET].digital_write(:HIGH)
sleep 1
sl.devhash[:GPIO][:DSL_RESET].digital_write(:LOW)
callback2 = lambda { |pin,edge,count| puts "[#{count}] #{pin} #{edge}"}
sl.devhash[:GPIO][:DSL_LINKUP].run_on_edge(callback2, :BOTH)
sleep 40