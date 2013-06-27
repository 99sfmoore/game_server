module FakeGame
 #template for requirements of a 2-player game to work with server
  class Board

    def initialize
      @board = (1..10).to_a
      @turns = 0
    end

    def make_move(move,mark)
      @board[move-1] = convert_mark(mark)
      @turns +=1
    end

    def valid?(move)
      @board[move-1].is_a?(Integer)
    end

    def display #string representation of current game state
      @board.map {|x| " #{x} "}.join
    end

    def game_over?
      @turns > 5
    end

    def draw?
      false
    end

    def convert_mark(mark)
      mark == 1 ? "L" : "R"
    end

  end

end


