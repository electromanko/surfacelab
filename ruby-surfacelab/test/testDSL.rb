require 'rubygems'
require 'socket'
require 'bcrypt'

#out = `env`
#puts out

require 'serialport'
require 'beaglebone'

class TestDSL
    def initialize
        @server = TCPServer.open(7788)    # Socket to listen on port 2000
        @serialport = SerialPort.new(2, 1500000, 8, 1, SerialPort::NONE)
        @status = "stoped"
    end
    
    def start(blockSize, tloop=false)
        if @status == "stoped"
            unless tloop
                
                    
                    @status="started"
            else
                    @thrRecvLoop = Thread.new {
                        while true do
                            @serialport.write(@serialport.getc)
                        end
                    }
                    @status="looped"
            end
        end
    end
    
    def stop
        if @status == "started"
            
            @status="stoped"
        elsif @status == "looped"
            @thrRecvLoop.exit
            @thrRecvLoop=nil
            @status="stoped"
        end
    end
    
    def status
        @status
    end
end

=begin
server = TCPServer.open(2000)    # Socket to listen on port 2000
loop {                           # Servers run forever
   client = server.accept        # Wait for a client to connect
   sp = SerialPort.new(2, 1500000, 8, 1, SerialPort::NONE)
   #client.puts(Time.now.ctime)   # Send the time to the client
   thrRecv = Thread.new {
        while true do
          client.printf("%c", sp.getc)
        end
    }
    while (l = client.gets) do
        sp.write(l)
    end
   client.puts "Closing the connection. Bye!"
   thrRecv.join
   sleep 10
   client.close                  # Disconnect from the client
   sp.close
}
=end
