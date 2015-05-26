game_server
===========
"game_manager" adds 2-player games (Connect Four & Tic-Tac-Toe) & then runs "threaded_game_server",
which accepts multiple requests from "game_client" to play 1 or 2 player games.

"tictax_server" allows AIs to play against each other using "tic_tax_client_sinatra"

Gameplay & AI is in "faster_tic_tac_toe_sockets" and "connect_four_sockets"

"game_tester" is to debug the games outside of the threaded server enviroment
