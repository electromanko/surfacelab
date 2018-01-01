require "socket"
require "serialport"


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

