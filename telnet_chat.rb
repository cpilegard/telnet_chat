require 'socket'


class Client
  attr_reader :socket
  attr_accessor :name

  def initialize(socket)
    @socket = socket
    # @name = socket.gets("What's your name?")
  end
end

class ChatServer

  def initialize(port)
    @tcpserver = TCPServer.new(port)
    # @tcpserver.setsockopt( Socket::SOL_SOCKET, Socket::SO_REUSEADDR, 1 )
    @connections = []
    @connections << @tcpserver
    puts "Server started..."
  end

  def add_connection
    new_connection = @tcpserver.accept
    @connections << new_connection

    Client.new(new_connection)

    new_connection.write("~~~~~Welcome to the Island Foxes chat room!~~~~~\n")
    new_connection.write("> ")
  end

  def distribute_message(message, sender)
    @connections.each do |connection|
      send_message(connection, message, sender)
    end
  end

  def send_message(socket, message, sender_socket)
    unless socket == @tcpserver
      socket.write("#{sender_socket.peeraddr[2]} says:  #{message}")
      socket.write("> ")
    end
  end

  def start
    while true
      # connected_sockets = @connections.map { |c| c.socket }
      incoming = IO.select(@connections, nil)

      if incoming != nil

        for socket in incoming[0]
        # incoming[0].each do |socket|
          if socket == @tcpserver
            add_connection
          else
            msg = socket.gets
            distribute_message(msg, socket)
          end
        end
      end
    end
  end

end



# port = ARGV[0]
chat_room = ChatServer.new(2000)
chat_room.start