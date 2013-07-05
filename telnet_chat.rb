require 'socket'


class Client
  @@next_color_holder = rand(6) #start with random color each time

  attr_reader :socket, :name, :original_name

  def initialize(socket, name)
    @socket = socket

    @original_name = name
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
    @currently_logged_in = []
    @connections << @tcpserver
    puts "Server started..."

    @commands = "COMMANDS: -help, -exit, -users, -pm [name] [text]\n"
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
    new_connection.write("#{@commands}\n")
    new_connection.write("\n> ")
    distribute_message("#{new_person.name} has joined\n", @connections[0])

    # distribute_message("Users: [#{currently_logged_in.join(", ")}]\n", @connections[0])
  end

  def currently_logged_in
    people = []
    @connections.each do |connection|
      unless connection == @tcpserver
        people << (get_person_from_socket(connection)).name
      end
    end
    people.join(", ")
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
        name = get_person_from_socket(sender_socket).name
      end
      socket.write("#{name}:  #{message}")
      socket.write("> ")
    end
  end

  def get_person_from_socket(socket)
    @people.each do |person|
      if person.socket == socket
        return person
      end
    end
  end

  def get_person_from_name(name)
    @people.each do |person|
      if person.original_name == name
        return person
      end
    end
    nil
  end

  def start
    while true
      incoming = IO.select(@connections, nil)

      if incoming != nil

        incoming[0].each do |socket|
          if socket == @tcpserver
            add_connection
          else
            msg = socket.gets.split(' ', 3)
            if msg[0] == "-exit"
              @connections.delete(socket)
              leaving = get_person_from_socket(socket)
              @people.delete(leaving)
              socket.close
              distribute_message("#{leaving.name} has left\n", @connections[0])
            elsif msg[0] == "-help"
              send_message(socket, @commands, @connections[0])
            elsif msg[0] == "-users"
              send_message(socket, "Users: [#{currently_logged_in}]\n", @connections[0])
            elsif msg[0] == "-pm" && msg.length == 3
              target = get_person_from_name(msg[1])
              if target != nil
                send_message(target.socket, "[private] " + msg[2], socket)
                socket.write("> ")
              end
            else
              distribute_message(msg.join(' ') + "\n", socket)
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