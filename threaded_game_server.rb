require 'socket'
require 'thread'
require_relative 'connect_four_sockets'
require_relative 'tic_tac_toe_sockets'

# Server to allow multiple games of Connect Four and TicTacToe
# Currently 2 player only.  Play against computer to be implemented
# run 'connect_four_client.rb' to connect
# need to deal with end of game - play again or disconnect




class Player
  attr_reader :name, :mark, :interrupted
  attr_accessor :is_playing

  def initialize(conn, name)
    @conn = conn
    @name = name
    @mark = 1
    @is_playing = true
    @interrupted = false
  end

  def is_player2
    @mark = 2
  end

  def interrupt
    @interrupted = true
  end

  def reset
    @interrupted = false
  end

  def tell(string)
    @conn.puts(string)
  end

  def ask(string) #returns input from client in response to string
    @conn.puts(string)
    @conn.puts("GET")
    @conn.gets.chomp
  end
  
  def get_move(board)
    begin
      move = ask("#{@name}, it's your turn.  Make a move.").to_i
      tell("Not a valid move.") if !board.valid?(move)
    end until board.valid?(move)
    move
  end

end

class ComputerPlayer
  attr_reader :name, :mark, :interrupted
  attr_accessor :is_playing

  def initialize(level)
    @level = level
    @name = "HAL"
    @mark = 2
    @interrupted = false
  end

  #these methods are here to allow for the same game loop for a 1 or 2 player game.
  #is there a better way to do this?

  def tell(string)
    #does nothing
  end

  def ask(string)
    #does nothing
  end

  def get_move(board)
    board.auto_move(@level,@mark)
  end
end


class Game
  attr_reader :game_board, :name, :active_player, :inactive_player, :inplay

  def initialize(game_type, player1, player2 = nil)
    if game_type == "C" || game_type == "Connect Four"
      @game_board = ConnectFour::Board.new
      @name = "Connect Four"
    else
      @game_board = TicTacToe::Board.new
      @name = "Tic Tac Toe"
    end
    @active_player = player1
    @inplay = false
    add_player(player2) and @inplay = true if player2
  end

  def add_player(player2)
    if rand(2) == 0
      @inactive_player = player2
    else
      @inactive_player = @active_player
      @active_player = player2
    end
    @inplay = true
  end

  def convert(mark)
    if @name == "Connect Four"
      mark == 1 ? result = "red" : result = "black"
    else
      mark == 1 ? result =  "X" : result = "O"
    end
    result
  end

  def wait
    begin
    end until @inplay
  end

  def starting_state
    "#{@active_player.name} will be #{convert(@active_player.mark)} and #{@inactive_player.name} will be #{convert(@inactive_player.mark)}.\n
     #{@active_player.name} will go first"
  end

  def tell_both(string)
    @active_player.tell(string)
    @inactive_player.tell(string)
  end

  def get_move
    @inactive_player.tell("Waiting for #{@active_player.name} to make a move.")
    move = @active_player.get_move(@game_board)
    @game_board.make_move(move,@active_player.mark)
  end

  def valid?(move)
    @game_board.valid?(move)
  end

  def switch_players
    temp = @active_player
    @active_player = @inactive_player
    @inactive_player = temp
  end

  def display
    @game_board.display
  end

  def game_over?
    @game_board.game_over?
  end

  def endgame
    tell_both("Game Over.")
    if @game_board.draw?
      tell_both("It's a draw.")
    else
      @inactive_player.tell("#{inactive_player.name}, you win!")
      p @active_player
      @active_player.tell("Sorry, #{active_player.name}, you lost.")
    end
    @active_player.is_playing = false
    @inactive_player.is_playing = false
  end

end


class Server

  def initialize(port = 21)
    @control_socket = TCPServer.new(port)
    puts "Server initialized on port #{port}"
    @games = []
    @thread_list = []
    @game_lock = Mutex.new
  end

  def start_new_game(new_player)
    begin
      game_choice = new_player.ask("Would you like to play Connect Four (C) or TicTacToe (T)? (C/T)").upcase
    end until game_choice == "C" || game_choice == "T"

    new_game = Game.new(game_choice,new_player)

    begin
      player_choice = new_player.ask("Do you want to play against the computer (C) or wait for someone to join (W)? (C/W)").upcase
    end until player_choice == "C" || player_choice == "W"

    if player_choice == "C"
      begin
        level = new_player.ask("Do you want an easy(1), medium(2), or hard(3) game?").to_i
      end until (level >= 1 && level <= 3)
      new_game.add_player(ComputerPlayer.new(level))
      game_in_play(new_game)  
    else #wait for second player
      @games << new_game
      new_player.tell("Please wait for a second player to join")
      begin
        response = new_player.ask("Do you want to play #{new_game.name} against the computer while you're waiting? (Y/N)").upcase
      end until response == "Y" || response == "N"
      if response == "Y"
        wait_game = Game.new(game_choice, new_player)
        begin
          level = new_player.ask("Do you want an easy(1), medium(2), or hard(3) game?").to_i
        end until (level >= 1 && level <= 3)
        wait_game.add_player(ComputerPlayer.new(level))
        game_in_play(wait_game)  
      end
      while new_game.inplay == false
        sleep(10)
      end
    end
  end

  def game_in_play(current_game)
    current_game.tell_both(current_game.starting_state)
    current_game.tell_both(current_game.display)
    begin
      current_game.get_move
      current_game.tell_both(current_game.display)
      current_game.switch_players
    end until current_game.game_over? || current_game.active_player.interrupted || current_game.inactive_player.interrupted
    if current_game.active_player.interrupted
      current_game.active_player.tell("This game is cancelled.")
      current_game.active_player.reset
    elsif current_game.inactive_player.interrupted
      current_game.inactive_player.tell("This game is cancelled.")
      current_game.inactive_player.reset
    else
      current_game.endgame
    end
  end


  def select_game(new_player)
    new_player.tell("Your choices are: ")
    choices = @games.find_all {|g| !g.inplay } 
    choices.each_with_index do |game, i|
      new_player.tell("#{i+1})  #{game.active_player.name} is waiting to play #{game.name}")
    end
    new_player.tell("#{choices.size+1}) Play your own game.")
    game_choice = new_player.ask("Choose an option: 1 - #{choices.size+1}").to_i
    if game_choice > choices.size
      start_new_game(new_player)
    else
      #@game_lock.synchronize do# need to somehow lock the choices, currently 2 people can join the same game -- kicks original player out
        current_game = choices[game_choice-1]
        if current_game.inplay
          new_player.tell("Sorry, that game was just taken.")
          select_game(new_player)
        else
        new_player.tell("Waiting to connect....")
        new_player.is_player2
        current_game.active_player.interrupt
        while current_game.active_player.interrupted 
          #do nothing until "wait_game" is finished
        end  
        current_game.active_player.tell("#{new_player.name} will be joining you.")
        current_game.add_player(new_player)
        end
      #end # end synchronize / Mutex doesn't work (? because it never gets to end of if/else & unlocks ?)
      game_in_play(current_game)
    end
  end

  def run
    @thread_list << Thread.new do
      Socket.accept_loop(@control_socket) do |conn|
        @thread_list << Thread.new do
          conn.puts("Welcome.")
          conn.puts("What is your name?")
          conn.puts("GET")
          name = conn.gets.chomp.capitalize
          new_player = Player.new(conn,name)
          begin 
            if @games == [] || @games.all? {|g| g.inplay} 
              start_new_game(new_player)
            else
              select_game(new_player)
            end
            while new_player.is_playing
              sleep(5) #what's the right time for this?  Better way to do?
            end
            begin
              conn.puts("Do you want to play another game? (Y/N)")
              conn.puts("GET")
              response = conn.gets.chomp.upcase
            end until response == "Y" || response == "N"
            new_player.is_playing = true
          end until response == "N"
          conn.puts("Goodbye")
          conn.puts("END")
          conn.close
        end #thread
      end #socket loop
    end #orig thread
    @thread_list.each {|thr| thr.join}
  end #run          
end #server class



server = Server.new(4481)
p server
server.run



      
