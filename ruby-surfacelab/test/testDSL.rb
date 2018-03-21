require 'rubygems'
require 'socket'
require 'bcrypt'

#out = `env`
#puts out

require 'serialport'
require 'beaglebone'
include Beaglebone



class TestDSL
    def initialize
        # Select BAUD 1500000
        GPIOPin.new(:P9_28, :OUT).digital_write(:HIGH)
        GPIOPin.new(:P9_31, :OUT).digital_write(:HIGH)
        @server = TCPServer.open(7788)    # Socket to listen on port 2000
        @serialport = SerialPort.new(2, 1500000, 8, 1, SerialPort::NONE)
        @status = {:state => "stoped"}
        reset_statistics
    end
    
    def start(blockSize, tloop=false)
        if @status[:state] == "stoped"
            unless tloop
                @status[:blockSize]=Integer(blockSize)
                @thrSend = Thread.new {
                        test_all
                        stop
                }
                @status[:state]="started"
            else
                @thrRecvLoop = Thread.new {
                    while true do
                        @serialport.write(@serialport.getc)
                    end
                }
                @status[:state]="looped"
            end
        end
    end
    
    def stop
        if @status[:state] == "started"
            @status[:state]="stoped"
            @thrSend.exit unless @thrSend.nil?
        elsif @status[:state] == "looped"
            @thrRecvLoop.exit
            @thrRecvLoop=nil
        end
        @status[:state]="stoped"
    end
    
    def test_all
        reset_statistics
        @serialport.flush_input
        @serialport.read_timeout=10000
        i=0
        while i< @status[:blockSize] do
            sndNum=rand(256)
            @status[:iter] += 1
            @serialport.write([sndNum].pack("C"))
            @status[:c_send]+=1
            rawrnmb = @serialport.read(1).unpack("C")
            rcvNum = rawrnmb.nil? ? 0 : rawrnmb[0]
            @status[:sstr]+="#{sndNum} "
            @status[:rstr]+="#{rcvNum} "
            if sndNum == rcvNum
                @status[:c_recv]+=1
            else
                @status[:c_err]+=1
                #@serialport.flush_input
            end
            i+=1
        end
    end
    
    def reset_statistics
        @status[:c_send]=@status[:c_recv]=@status[:c_err]=@status[:iter]=0
        @status[:sstr]=""
        @status[:rstr]=""
    end
    
    def status
        @status
    end
end

=begin
t = TestDSL.new
t.start(1000)
sleep 20
puts t.status
sleep 5
t.stop
=end 

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
