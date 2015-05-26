#Two Player Game Server

Game server implemented using sockets and threads to host multiple instances of 2 player games such as Tic-Tac-Toe and Connect Four.

Run game_manager.rb to load games and start server.  Run game_client.rb to connect and play.

Server will run any 2 player game that conforms to the methods described in fakegame.rb and will allow people to play against each other or against an AI.

Tic-Tac-Toe and Connect Four games have 3 AI difficulty levels implemented using minimax.

The TicTax server was built using Sinatra to allow the many different Tic-Tac-Toe and Connect Four AIs built by Recursers to play against each other.
