require_relative 'connect_four_sockets'
require_relative 'tic_tac_toe_sockets'

puts "Choose game (C/T)"
choice = gets.chomp.upcase
choice == "C" ? board = ConnectFour::Board.new : board = TicTacToe::Board.new
puts "Player 1 name"
player1 = [gets.chomp.capitalize, 1, 0]
puts "Computer or human? (C/H)"
if gets.chomp == "C"
	puts "What level?"
	level = gets.chomp.to_i
	player2 = ["HAL",2, 1]
else
	puts "Player 2 name"
    player2 = [gets.chomp.capitalize, 2, 0]
end
current_player = player2
puts board.display

begin
	puts current_player[0] + " moves"
	if current_player.last == 1
		move = board.auto_move(level, current_player[1])
	else
	  move = gets.chomp.to_i
	end
	board.make_move(move,current_player[1])
	puts board.display
	board.write_tictax
	current_player == player1 ? current_player = player2 : current_player = player1
end until board.game_over?
if board.draw?
	puts "It's a draw"
else
	puts current_player[0]+ " did not win."
end


