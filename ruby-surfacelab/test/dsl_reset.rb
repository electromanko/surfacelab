require_relative '../lib/surfacelab/surfacelab'
require 'beaglebone'
include Beaglebone
include Surfacelab

sl = SurfacelabDevice.new
sl.devhash[:GPIO][:DSL_MASTER].digital_write(:HIGH)
sl.devhash[:GPIO][:DSL_RESET].digital_write(:HIGH)
sleep 1
sl.devhash[:GPIO][:DSL_RESET].digital_write(:LOW)