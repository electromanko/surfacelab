#!/home/debian/.rvm/scripts/rvm/ruby"
##!/usr/bin/env ruby

require "bundler/setup"
require "spi"
require 'spi/driver/spidev'

#s=SPI.new(device: '/dev/spidev1.0')
s=SPI::Driver::SPIdev.new(device: '/dev/spidev1.0')
s.speed=500000
raw = s.xfer(txdata: [0x41,0xFF,0x40,0x38])
p raw

require "serialport"

if ARGV.size < 4
  STDERR.print <<EOF
  Usage: ruby #{$0} num_port bps nbits stopb
EOF
  exit(1)
end

sp = SerialPort.new(ARGV[0].to_i, ARGV[1].to_i, ARGV[2].to_i, ARGV[3].to_i, SerialPort::NONE)

open("/dev/tty", "r+") { |tty|
  tty.sync = true
  Thread.new {
    while true do
      tty.printf("%c", sp.getc)
    end
  }
  while (l = tty.gets) do
    sp.write(l.sub("\n", "\r"))
  end
}

sp.close