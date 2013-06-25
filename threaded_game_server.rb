require 'socket'
require 'thread'
require_relative 'connect_four_sockets'
require_relative 'faster_tic_tac_toe_sockets'

# Server to allow multiple games of Connect Four and TicTacToe
# run 'game_client.rb' to connect


class Player
  attr_reader :name, :mark, :interrupted
  attr_accessor :is_playing 

  def initialize(conn, name)
    @conn = conn
    @name = name
    @mark = 1
    @is_playing = false
    @interrupted = false
  end

  def is_player2
    @mark = -1
  end

  def tell(string)
    @conn.puts(string)
  end

  def ask(string, acceptable_responses = nil) #returns input from client in response to string
    if acceptable_responses # want to do this without if/else.  Is there a wildcard []
      acceptable_responses.map!{|x| x.to_s}
      begin
        @conn.puts(string)
        @conn.puts("GET")
        response = @conn.gets.chomp
      end until acceptable_responses.any? {|x| x.casecmp(response) == 0}
    else
      @conn.puts(string)
      @conn.puts("GET")
      response = @conn.gets.chomp
    end
    response
  end
  
  def get_move(board)
    begin
      move = ask("#{@name}, it's your turn.  Make a move.").to_i
      tell("Not a valid move.") if !board.valid?(move)
    end until board.valid?(move)
    move
  end

  def interrupt
    if @is_playing
      tell("This game is cancelled")
      @interrupted = true
    end
  end

  def reset
    @interrupted = false
  end

end

class ComputerPlayer
  attr_reader :name, :mark, :interrupted
  attr_accessor :is_playing

  def initialize(level)
    @level = level
    @name = "HAL"
    @mark = -1
    @interrupted = false
  end

  #these methods are here to allow for the same game loop for a 1 or 2 player game.
  #is there a better way to do this?

  def tell(string)
    #does nothing
  end

  def ask(string, acceptable_responses = nil)
    if acceptable_responses
      return acceptable_responses[rand(acceptable_responses.size)]
    end
    #does nothing
  end

  def get_move(board)
    board.auto_move(@level,@mark)
  end

  def interrupt
    #do nothing
  end

  def reset
    #do nothing
  end
end


class Game
  attr_reader :game_board, :game_info, :name, :active_player, :inactive_player, :inplay, :interrupted

  def initialize(game_info, player1, player2 = nil)
    @game_info = game_info
    @game_board = Module.const_get(game_info[:module])::Board.new
    @name = game_info[:name]
    @mark_strings = game_info[:mark_descs]
    @active_player = player1
    @inplay = false
    @interrupted = false
    add_player(player2) and @inplay = true if player2
  end

  def add_player(player2)
    player2.is_playing = true
    @active_player.is_playing = true
    if rand(2) == 0
      @inactive_player = player2
    else
      @inactive_player = @active_player
      @active_player = player2
    end
    @inplay = true
  end

  def convert(mark)
    mark == 1 ? @mark_strings[0] : @mark_strings[1]
  end

  def interrupted?
    @active_player.interrupted || @inactive_player.interrupted
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

  def reset_players
    @active_player.reset
    @inactive_player.reset
  end

  def stop_players
    reset_players
    @active_player.is_playing = false
    @inactive_player.is_playing = false
  end

  def endgame
    tell_both("Game Over.")
    if @game_board.draw?
      tell_both("It's a draw.")
    else
      @inactive_player.tell("#{inactive_player.name}, you win!")
      @active_player.tell("Sorry, #{active_player.name}, you lost.")
    end
  end

end


class Server

  @@available_games = [ { :name => "Connect Four",
                          :module => "ConnectFour",
                          :mark_descs => ["red","black"]
                        },
                        { :name => "Tic Tac Toe",
                          :module => "TicTacToe",
                          :mark_descs => ["X","O"]
                        } ]

  def self.add_game(name,mod,mark_descs)
    @@available_games << {:name => name,
                          :module => mod,
                          :mark_descs => mark_descs
                        }
  end


  def initialize(port = 21)
    @control_socket = TCPServer.new(port)
    puts "Server initialized on port #{port}"
    p @@available_games
    @games = []
    @thread_list = []
    @game_lock = Mutex.new
  end

  
  def list_games
    response_string = ""
    @@available_games.each_with_index do |game,i|
      response_string << "\n#{i+1}) #{game[:name]}"
    end
    response_string
  end


  def pick_game(new_player)
    game_choice = new_player.ask("Would you like to play?"+list_games,(1..@@available_games.size).to_a).to_i
    game_info = @@available_games[game_choice-1]
    Game.new(game_info, new_player)
  end

  def start_new_game(new_player)
    new_game = pick_game(new_player)
    player_choice = new_player.ask("Do you want to play against the computer (C) or wait for someone to join (W)? (C/W)",["C","W"]).upcase
    if player_choice == "C"
      start_single_player(new_player, new_game)
    else #wait for second player
      @games << new_game
      new_player.tell("Please wait for a second player to join")
      while new_game.inplay == false
        response = new_player.ask("Do you want to play against the computer while you're waiting? (Y/N)",["Y","N"]).upcase
        if response == "Y"
          wait_game = pick_game(new_player)
          start_single_player(new_player, wait_game)
        end
        new_player.tell("Still waiting for a second player to join....")
        sleep(5)
        response = new_player.ask("Do you want to stop waiting? (Y/N)",["Y","N"]).upcase
        if response == "Y" 
          @games.delete(new_game)
          return
        end
      end
    end
  end

  def start_single_player(new_player, new_game)
    level = new_player.ask("Do you want an easy(1), medium(2), or hard(3) game?",["1","2","3"]).to_i
    new_game.add_player(ComputerPlayer.new(level))
    game_in_play(new_game)  
  end

  def game_in_play(current_game)
    current_game.tell_both(current_game.starting_state)
    current_game.tell_both(current_game.display)
    begin
        current_game.get_move
        current_game.tell_both(current_game.display) unless current_game.interrupted?
        current_game.switch_players
    end until current_game.game_over? || current_game.interrupted?
    if current_game.interrupted?
      current_game.reset_players
    else
      current_game.endgame
      play_again(current_game)
    end
  end

  def play_again(game)
    response1 = game.active_player.ask("Do you want to play #{game.inactive_player.name} again? (Y/N)",["Y","N"]).upcase == "Y"
    response2 = game.inactive_player.ask("Do you want to play #{game.active_player.name} again? (Y/N)",["Y","N"]).upcase == "Y"
    if response1 && response2
      game.tell_both("Great, you'll play again!")
      new_game = Game.new(game.game_info,game.active_player,game.inactive_player)
      game_in_play(new_game)
    elsif response1
      game.active_player.tell("Sorry, #{game.inactive_player.name} doesn't want to play with you anymore.")
    elsif response2
      game.inactive_player.tell("Sorry, #{game.active_player.name} doesn't want to play with you anymore.")
    end
    game.stop_players
  end

  def select_game(new_player)
    new_player.tell("Your choices are: ")
    choices = @games.find_all {|g| !g.inplay } 
    choices.each_with_index do |game, i|
      new_player.tell("#{i+1}) #{game.active_player.name} is waiting to play #{game.name}")
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
            response = new_player.ask("Do you want to play another game? (Y/N)",["Y","N"]).upcase
          end until response == "N"
          new_player.tell("Goodbye")
          new_player.tell("END")
          conn.close
        end #thread
      end #socket loop
    end #orig thread
    @thread_list.each {|thr| thr.join}
  end #run          
end #server class



# server = Server.new(4481)
# server.run



      
