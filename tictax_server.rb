require 'sinatra'
require 'json'
require_relative 'jsonable'
require_relative 'connect_four_sockets'

class GameState
  attr_reader :player1, :player2
  attr_accessor :board 
  @@player_id = 1 ## 0 is used for draw state

  def initialize(game_type)
    @game_type = game_type
    if game_type == "C4"
      @board = ConnectFour::Board.new 
    elsif game_type == "TTT" #ttt  X is player 1, O is player 2
      @board = Array.new(9){0}
    end
    @player1 = @@player_id
    @player2 = @@player_id + 1
    @has_turn = @player1
    @@player_id +=2
    @last_board = @board.clone
    @winner = nil
    p @board
  end

  def turn
    @has_turn
  end

  def switch_turn
    @has_turn == @player1 ? @has_turn = @player2 : @has_turn = @player1
  end

  def json(player)
    @game_type == "TTT" ? write_board = @board : write_board = Jsonable.new(@board.grid).ready_for_json
    if @winner
      {'board' => write_board, 'winner' => @winner}.to_json
    elsif player == turn
      {'board' => write_board, 'player_id' => player, 'status' => "your turn"}.to_json
    else
      {'player_id' => player, 'status' => "hold tight"}.to_json
    end
  end

  def validate(new_board)
    change = 0
    if @game_type == "TTT"
      @board.each_with_index do |x,i|
        change +=1 if x != new_board[i]
        change +=10 if x != 0 && x != new_board[i]  #no overwrites
      end
      if change == 1
        @board = new_board
        switch_turn
      end #else case for cheaters
    else #C4
      attempted_move = []
      converted_board = Jsonable.new.from_json!(new_board).two_d_array
      converted_board.each_with_index do |col, i|
        col.each_with_index do |cell,j|
          if cell!= @board.grid[i][j]
            change +=1
            attempted_move = [i,cell]
          end
          change =+10 if cell != @board.grid[i][j] && !@board.grid[i][j].nil? #no overwrites
        end
      end
      if change == 1
        @board.make_move(attempted_move.first+1,attempted_move.last)
        switch_turn 
      end # else case for cheaters
    end
  end

  def check_winner
    if @game_type == "TTT"
      winstates = []
      [0,3,6].each do |i|
        winstates << @board[i..i+2].inject(:+).abs
      end
      (0..2).each do |i|
        winstates << (@board[i] + @board[i+3] + @board[i+6]).abs
      end
      winstates << (@board[0] + @board[4] + @board[8]).abs
      winstates << (@board[3] + @board[4] + @board[6]).abs
      if winstates.any?{|state| state == 3}
        turn == @player2 ? @winner = @player1 : @winner = @player2
      end
    else # C4
      if @board.game_over? && !@board.draw?
        turn == @player2 ? @winner = @player1 : @winner = @player2
      end
    end
  end

  def check_game_over
    if @game_type == "TTT"
      @winner = 0 if !@board.any?{|x| x == 0}
    else 
      @winner = 0 if @board.draw?
    end
    check_winner
  end

end

$waiting_game = nil
$waiting_C4_game = nil
$games = []

get '/play_request/:game_type' do
  if params[:game_type] == "TTT"
    if $waiting_game.nil?
      g = GameState.new("TTT")
      $waiting_game = g
      $games << g
      redirect "/get_board/#{g.player1}/#{params[:game_type]}"
    else
      g = $waiting_game
      $waiting_game = nil
      content_type :json
      {'player_id' => g.player2}.to_json
    end
  elsif params[:game_type] == "C4"
    puts "I'm in C4"
    if $waiting_C4_game.nil?
      g = GameState.new("C4")
      $waiting_C4_game = g
      $games << g
      redirect "/get_board/#{g.player1}/#{params[:game_type]}"
    else
      g = $waiting_C4_game
      $waiting_C4_game = nil
      content_type :json
      {'player_id' => g.player2}.to_json
    end
  end
end

get '/get_board/:player_id/:game_type' do
  the_game = $games.find {|g| g.player1 == params[:player_id].to_s.to_i || g.player2 == params[:player_id].to_s.to_i}
  content_type :json
  the_game.json(params[:player_id].to_s.to_i)
end


post '/submit_board/:player_id/:game_type' do 
  the_game = $games.find {|g| g.turn == params[:player_id].to_s.to_i}
  if the_game
    game_hash = JSON.parse(params[:data])
    the_game.validate(game_hash["board"])
    the_game.check_game_over
  end
end
