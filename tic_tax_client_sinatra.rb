require 'httparty'
require_relative 'faster_tic_tac_toe_sockets'
require_relative 'connect_four_sockets'


puts "Are we playing TicTacToe (T) or Connect Four (C) ?"
choice = gets.chomp.upcase
puts "How smart should we be? (1) Dumb, (2) Average, (3) Genius"
level = gets.chomp.to_i #could add a check here
if choice == "T"
  game = TicTacToe::Board.new
  suffix = "/TTT"
else
  game = ConnectFour::Board.new 
  suffix = "/C4"
end
host = "localhost" #"thomasballinger.com"
port = 4567  


puts game.display


init_hash = HTTParty.get("http://#{host}:#{port}/play_request#{suffix}").parsed_response 
if init_hash["board"] 
  player_id = init_hash["player_id"]
  mark = 1
  game.read_tictax(init_hash["board"])
  game.make_move(game.auto_move(level,mark),mark)
  puts game.display
  options = {:body => {:data => game.write_tictax.to_json}}
  HTTParty.post("http://#{host}:#{port}/submit_board/#{player_id}#{suffix}",options)
  
else
  player_id = init_hash["player_id"]
  mark = -1
end


begin
  begin 
    puts "requesting"
    response = HTTParty.get("http://#{host}:#{port}/get_board/#{player_id}#{suffix}").parsed_response
    sleep 3
  end until response["status"] == "your turn" || response["winner"]
  game.read_tictax(response["board"])
  puts game.display
  if response["winner"] == player_id
    puts "This was supposed to be impossible. You won."
  elsif response["winner"] == 0
    puts "Surprise! It's a draw.  Who would have thought?"
  elsif response["winner"]
    puts "More debugging needed.  You lost."
  else
    game.make_move(game.auto_move(level,mark),mark)
    puts game.display
    options = {:body => {:data => game.write_tictax.to_json}}
    HTTParty.post("http://#{host}:#{port}/submit_board/#{player_id}#{suffix}",options)
  end
end until response["winner"]
