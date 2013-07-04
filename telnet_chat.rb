require 'socket'


class Client
  @@next_color_holder = 2 #start with yellow, just because

  attr_reader :socket, :name
  # attr_accessor :name

  def initialize(socket, name)
    @socket = socket

    col = @@next_color_holder % 7 + 1
    @@next_color_holder += 1
    @name = "\033[3#{col}m#{name}\033[0m"
  end
end

class ChatServer

  def initialize(port)
    @tcpserver = TCPServer.new(port)
    # @tcpserver.setsockopt( Socket::SOL_SOCKET, Socket::SO_REUSEADDR, 1 )
    @connections = []
    @people = []
    @connections << @tcpserver
    puts "Server started..."
  end

  def add_connection
    new_connection = @tcpserver.accept
    @connections << new_connection

    new_connection.write("\nPlease enter your name: ")
    name = new_connection.gets.chomp
    new_person = Client.new(new_connection, name)
    @people << new_person

    new_connection.write("\n\n~~~~~Welcome, #{name}~~~~~\n\n")
    new_connection.write("> ")
  end

  def distribute_message(message, sender)
    @connections.each do |connection|
      send_message(connection, message, sender)
    end
  end

  def send_message(socket, message, sender_socket)
    unless socket == @tcpserver
      name = get_name(sender_socket)
      socket.write("#{name} says:  #{message}")
      socket.write("> ")
    end
  end

  def get_name(socket)
    @people.each do |person|
      if person.socket == socket
        return person.name
      end
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