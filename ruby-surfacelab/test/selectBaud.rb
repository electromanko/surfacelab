require 'beaglebone'
include Beaglebone

GPIOPin.new(:P9_28, :OUT).digital_write(:HIGH)
GPIOPin.new(:P9_31, :OUT).digital_write(:HIGH)
gets