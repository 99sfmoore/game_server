require 'httparty'
require_relative 'faster_tic_tac_toe_sockets'


host = "thomasballinger.com"
port = 8001

puts game.display


init_hash = JSON.parse(HTTParty.get("http://#{host}:#{port}/play_request").parsed_response)
if init_hash["board"].all? {|x| x ==0 } #player1
  player_id = init_hash["player1"]
  mark = 1
 else
  player_id = init_hash["player2"]
  mark = -1
end
if init_hash["board"] 
  game.read_tictax(init_hash["board"])
  game.make_move(game.auto_move(3,mark),mark)
  puts game.display
  options = {:body => {:data => game.write_tictax.to_json}}
  HTTParty.post("http://#{host}:#{port}/submit_board/#{player_id}",options)
end

5.times do #currently no endgame on server
  begin 
    puts "requesting"
    response = JSON.parse(HTTParty.get("http://#{host}:#{port}/get_board/#{player_id}").parsed_response)
    p response
    sleep 5
  end until response["status"] != "hold tight"
  game.read_tictax(response["board"])
  puts game.display
  game.make_move(game.auto_move(3,mark),mark)
  puts game.display
  options = {:body => {:data => game.write_tictax.to_json}}
  HTTParty.post("http://#{host}:#{port}/submit_board/#{player_id}",options)
end