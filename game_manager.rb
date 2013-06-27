require_relative 'threaded_game_server'
require_relative 'connect_four_sockets'
require_relative 'faster_tic_tac_toe_sockets'
require_relative 'fakegame'


Server.add_game("Tic Tac Toe","TicTacToe",["X","O"])
Server.add_game("Connect Four","ConnectFour",["red","black"])
Server.add_game("Fake Game","FakeGame",["L","R"])
s = Server.new(4481)
s.run