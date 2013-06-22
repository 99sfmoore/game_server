require 'sinatra'
require 'json'

class GameState
  attr_reader :player1, :player2
  attr_accessor :board
  @@player_id = 1 ## 0 is used for draw state

  def initialize
    # X is player 1, O is player 2
    @board = Array.new(9){0}
    @player1 = @@player_id
    @player2 = @@player_id + 1
    @@player_id +=2
    @last_board = @board.dup
    @winner = nil
  end

  def turn
    [@player1, @player2][@board.inject(:+)]
  end

  def try_move(move)
    @board
  end

  def json(player)
    if @winner
      {'board' => @board, 'winner' => @winner}.to_json
    elsif player == turn
      {'board' => @board, 'player_id' => player, 'status' => "your turn"}.to_json
    else
      {'player_id' => player, 'status' => "hold tight"}.to_json
    end
  end

  def validate(new_board)
    change = 0
    @board.each_with_index do |x,i|
      change +=1 if x != new_board[i]
      change +=10 if x != 0 && x != new_board[i]  #no overwrites
    end
    if change == 1
      @board = new_board
    else
      #case for cheaters
    end
  end

  def check_winner
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
  end

  def check_game_over
    @winner = 0 if !@board.any?{|x| x == 0}
    check_winner
  end

end

$waiting_game = nil
$games = []

get '/play_request' do
  if $waiting_game.nil?
    g = GameState.new
    $waiting_game = g
    $games << g
    redirect "/get_board/#{g.player1}"
  else
    g = $waiting_game
    $waiting_game = nil
    content_type :json
    {'player_id' => g.player2}.to_json
  end
end

get '/get_board/:player_id' do
  the_game = $games.find {|g| g.player1 == params[:player_id].to_s.to_i || g.player2 == params[:player_id].to_s.to_i}
  content_type :json
  the_game.json(params[:player_id].to_s.to_i)
end


post '/submit_board/:player_id' do 
  the_game = $games.find {|g| g.turn == params[:player_id].to_s.to_i}
  if the_game
    game_hash = JSON.parse(params[:data])
    the_game.validate(game_hash["board"])
    the_game.check_game_over
  end
 
end





