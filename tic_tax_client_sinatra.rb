require 'httparty'
require_relative 'tic_tac_toe_sockets'

game = TicTacToe::Board.new
puts game.display


init_hash = HTTParty.get("http://localhost:4567/play_request").parsed_response #don't know why I'm not getting json
p init_hash
if init_hash["board"] 
  player_id = init_hash["player_id"]
  mark = 1
  game.read_tictax(init_hash["board"])
  game.make_move(game.auto_move(3,mark),mark)
  puts game.display
  options = {:body => {:data => game.write_tictax.to_json}}
  HTTParty.post("http://localhost:4567/submit_board/#{player_id}",options)
  
else
  player_id = init_hash["player_id"]
  puts "my player id is #{player_id}"
  mark = -1
end

begin
  begin 
    puts "requesting"
    puts "http://localhost:4567/get_board/#{player_id}"
    response = HTTParty.get("http://localhost:4567/get_board/#{player_id}").parsed_response
    #response = JSON.parse(HTTParty.get("http://localhost:5000/get_board/#{player_id}")) ?? not getting JSON
    p response
    sleep 5
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
    game.make_move(game.auto_move(3,mark),mark)
    puts "this is my move"
    puts game.display
    options = {:body => {:data => game.write_tictax.to_json}}
    HTTParty.post("http://localhost:4567/submit_board/#{player_id}",options)
  end
end until response["winner"]
