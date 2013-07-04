require 'socket'


class Client
  @@next_color_holder = rand(6) #start with random color each time

  attr_reader :socket, :name

  def initialize(socket, name)
    @socket = socket

    col = @@next_color_holder % 6 + 1
    @@next_color_holder += 1
    @name = "\033[3#{col}m#{name}\033[0m"
  end
end

class ChatServer

  def initialize(port)
    @tcpserver = TCPServer.new(port)
    @connections = []
    @people = []
    @connections << @tcpserver
    puts "Server started..."
  end

  def add_connection
    new_connection = @tcpserver.accept
    @connections << new_connection

    new_connection.write("\e[H\e[2J")
    new_connection.write("~~~~~Welcome to the Island Fox chat room~~~~~\n\n")
    new_connection.write("Please enter your name: ")
    name = new_connection.gets.chomp
    new_person = Client.new(new_connection, name)
    @people << new_person

    new_connection.write("\nWelcome, #{name}!\n")
    new_connection.write("--type 'exit' to close--\n")
    new_connection.write("\n> ")
    distribute_message("#{new_person.name} has joined\n", @connections[0])

    currently_logged_in = []
    @connections.each do |connection|
      @people.each do |person|
        if connection == person.socket
          currently_logged_in << person.name
        end
      end
    end

    distribute_message("Users: [#{currently_logged_in.join(", ")}]\n", @connections[0])
  end

  def distribute_message(message, sender)
    @connections.each do |connection|
      send_message(connection, message, sender)
    end
  end

  def send_message(socket, message, sender_socket)
    unless socket == @tcpserver
      if sender_socket == @tcpserver
        name = "\033[4mserver\033[0m"
      else
        name = get_name(sender_socket)
      end
      socket.write("#{name}:  #{message}")
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
      incoming = IO.select(@connections, nil)

      if incoming != nil

        incoming[0].each do |socket|
          if socket == @tcpserver
            add_connection
          else
            msg = socket.gets
            if msg == "exit\r\n"
              @connections.delete(socket)
              socket.close
            else
              distribute_message(msg, socket)
            end
          end
        end
      end
    end
  end

end

# port = ARGV[0]
chat_room = ChatServer.new(2000)
chat_room.start