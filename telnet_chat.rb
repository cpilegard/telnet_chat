require 'socket'


class Client
  attr_reader :socket
  attr_accessor :name

  def initialize(socket)
    @socket = socket
    # @name = "anonymous"
  end
end

class ChatServer

  def initialize(port)
    @tcpserver = TCPServer.new(port)
    @tcpserver.setsockopt( Socket::SOL_SOCKET, Socket::SO_REUSEADDR, 1 )
    @connections = []
    @connections << @tcpserver
    puts "Server started..."
  end

  def add_connection
    client = @tcpserver.accept #Client.new(@tcpserver.accept)
    @connections << client

    send_message(client, "Welcome to the chat room!\n")
    # client.name = client.socket.gets
    # puts client.socket


  end

  def distribute_message(message)
    @connections.each do |connection|
      send_message(connection, message)
    end
  end

  def send_message(socket, message)
    unless socket == @tcpserver
      socket.write("#{socket.peeraddr[2]} says:  #{message}")
      socket.write("> ")
    end
  end

  def start
    while true
      # connected_sockets = @connections.map { |c| c.socket }
      incoming = IO.select(@connections, nil)

      if incoming != nil

        for sock in incoming[0]
          if sock == @tcpserver
            add_connection
          else
            msg = sock.gets
            distribute_message(msg)
          end
        end
      end
    end
  end

end



# port = ARGV[0]
chat_room = ChatServer.new(2000)
chat_room.start