require 'httparty'
require_relative 'tic_tac_toe_sockets'

game = TicTacToe::Board.new
puts game.display


#init_hash = JSON.parse(HTTParty.get("http://localhost:4567/play_request"))
response = HTTParty.get("http://localhost:4567/play_request")
p response
p response.class
p init_hash
if init_hash["board"] 
  player_id = init_hash["player1"]
  mark = 1
  game.read_tictax(init_hash["board"])
  game.make_move(game.auto_move(3,mark),mark)
  puts game.display
  options = {:body => {:data => game.write_tictax.to_json}}
  HTTParty.post("http://localhost:5000/submit_board/#{player_id}",options)
  
else
  player_id = init_hash["player2"]
  mark = 2
end

5.times do #currently no endgame on server
  begin 
    puts "requesting"
    response = JSON.parse(HTTParty.get("http://localhost:5000/get_board/#{player_id}"))
    p response
    sleep 5
  end until response["status"] != "hold tight"
  game.read_tictax(response["board"])
  puts game.display
  continue = gets.chomp
  game.make_move(game.auto_move(3,mark),mark)
  puts game.display
  options = {:body => {:data => game.write_tictax.to_json}}
  HTTParty.post("http://localhost:5000/submit_board/#{player_id}",options)
end