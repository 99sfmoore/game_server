require 'colored'
require 'json'

module TicTacToe

  class Board
    attr_reader :turn 

    def initialize
      @grid = Array.new(9){0}
      @turns = 0 
    end 
 
    private

    def convert_mark(mark)
       mark == 1 ? "X" : "O"
    end

    def valid_moves
      moves = []
      (1..9).each do |i|  
        moves << i if @grid[i-1] == 0
      end
      moves
    end

    public

    def write_tictax 
      board_hash = {"board" => @grid}
    end

    def read_tictax(board) 
      @grid = board
    end

    def display 
      row_sep = "+---"*3+"+\n"
      rows = []
      @grid.each_with_index do |cell, index|
        if index == 0 
          rows << ""
        end
        if cell == 0
          rows << " #{index+1} "
        else
          rows << " #{convert_mark(cell)} ".red
        end
        if (index+1) % 3 == 0
          rows << "\n"+row_sep
        end
      end
      row_sep + rows.join("|")
    end

    def valid?(move)
      return false if move < 1 || move > 9
      @grid[move-1] == 0
    end

    def make_move(move,mark)
      @grid[move-1] = mark
      @turns +=1
    end

    def auto_move(level,mark)
      sign = convert_mark(mark)
      opp_sign = convert_mark(-mark)

      case level
      when 1  #computer picks randomly
        begin
          pick = rand(9)+1
        end until valid?(pick)
      
      when 2 #computer will block or win, but not think ahead 
        valid_moves.each do |i|
          tempboard = @grid.dup
          tempboard[i-1] = mark
          if game_over?(tempboard)
            pick = i
            return pick
          end
        end
        valid_moves.each do |i|
          tempboard = @grid.dup
          tempboard[i-1] = -mark
          if game_over?(tempboard)
            pick = i
            return pick
          end
        end
        begin
          pick = rand(9)+1
        end until valid?(pick)

      when 3 #minimax
        if valid?(5)
          pick = 5
        else
          possboards = []
          valid_moves.each do |i|
            tempboard = @grid.dup
            tempboard[i-1] = mark
            possboards[i] = get_score(tempboard,true,mark) 
          end
          pick = possboards.index(mark) || possboards.index(0) || possboards.index(-mark) 
        end
      end
        return pick
      end

    def get_score(board,my_turn,mark)
      winstates = []
      [0,3,6].each do |i|
        winstates << board[i..i+2].inject(:+).abs
      end
      (0..2).each do |i|
        winstates << (board[i] + board[i+3] + board[i+6]).abs
      end
      winstates << (board[0] + board[4] + board[8]).abs
      winstates << (board[2] + board[4] + board[6]).abs
      if winstates.any?{|state| state == 3}
        score = mark
      elsif !board.any?{|x| x == 0}
        score = 0
      else
        nextboards = []
        board.each_with_index do |x,i|
          if x == 0
            newboard = board.dup
            newboard[i] = -mark
            nextboards << newboard
          end
        end
        nextboards.map!{|bd| get_score(bd,!my_turn, -mark)}
        mark == 1 ? score = nextboards.min : score = nextboards.max
      end
      score
    end

    def game_over?(board = @grid)
      winstates = []
      [0,3,6].each do |i|
        winstates << board[i..i+2].inject(:+).abs
      end
      (0..2).each do |i|
        winstates << (board[i] + board[i+3] + board[i+6]).abs
      end
      winstates << (board[0] + board[4] + board[8]).abs
      winstates << (board[2] + board[4] + board[6]).abs
      if winstates.any?{|state| state == 3}
        return true
      elsif @turns == 9
        @turns +=1
        return true
      else
        false
      end
    end

    def draw?
      @turns > 9
    end
  end #class Board

end #module TicTacToe

