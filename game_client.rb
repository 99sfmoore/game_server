require 'socket'

#need to deal with end of game

class Client

  def initialize(host,port) # defaults??
    @connection = TCPSocket.new(host,port)
  end

  def run
    loop do
      message = @connection.gets.chomp
  
      if message == "GET"
        response = gets.chomp
        @connection.puts(response)
      elsif message == "END"
        break
      else
        puts message
      end
    end
  end


end

client = Client.new('localhost', 4481)

client.run

