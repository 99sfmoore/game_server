require 'colored'
require 'json'

module TicTacToe

  class Board
    attr_reader :turn 

    def initialize(grid = nil, turns = nil) #might not need params
      @grid = grid || Array.new(9){0}
      @turns = turns || 0 #might not need this
    end

    def clone #might not need this
      new_grid = rows.map {|r| r.dup}
      nb = Board.new(new_grid, @turns)
      nb
    end
 
    
    private
=begin
    def row(i) #returns array of entire ith row 
      @grid[i]
    end

    def rows #returns 2D array of all rows
      @grid
    end

    def col(i) #returns array of entire ith column
      @grid.map {|r| r[i]}
    end

    def cols #returns 2D array of all cols
      (0...@grid.size).map {|i| col(i)}
    end

    def cell(row_i,col_i)
      @grid[row_i][col_i]
    end

    def display_row(row)
      s = row.map do |x| 
        x.is_a?(Integer) ? " #{x} " : " #{x} ".red
      end
      "|"+s.join("|")+"|"
    end
          
    def convert_to_row(move)
      row = (move/3.0).ceil - 1
      row == 2 ? -1 : row
    end

    def convert_to_col(move)
      (move % 3) - 1
    end

    def diagonals_from(row_i, col_i)
      if row_i == col_i
        diag_left = [cell(row_i, col_i), cell(row_i-1, col_i-1), cell(row_i-2, col_i-2)]
      end
      
      if (row_i + col_i == -1) || (row_i + col_i == 2)
        diag_right = [cell(row_i, col_i), cell(row_i-1, col_i+1), cell(row_i-2, col_i-1)]
      end

      [diag_left || [], diag_right || [] ]
    end
=end

    def convert_mark(mark)
       mark == 1 ? "X" : "O"
    end

    def opp_mark(mark)
      mark == 1 ? mark = -1 : mark = 1
    end
=begin
    def num_to_grid(num)
      r = convert_to_row(num)
      c = convert_to_col(num)
      result_cell = cell(r,c)
      result_cell
    end
=end

    def valid_moves
      moves = []
      (0..8).each do |i| 
        moves << i if @grid[i] == 0
      end
      moves
    end

    public

    def write_tictax #needs to create actual tictax hash, not just board
      board_hash = {"board" => @grid}
    end

    def read_tictax(board) # to be finished
      @grid = board
    end

    def display #needs to be redone
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
      @grid[move] = mark
      #@last_move = [row_i, col_i, sign] #not sure if I need this
    end

    def auto_move(level,mark)
      puts "making my move"
      sign = convert_mark(mark)
      opp_sign = convert_mark(opp_mark(mark))

      case level
      when 1  #computer picks randomly
        begin
          pick = rand(9)+1
        end until valid?(pick)
      # this needs to be redone
      when 2 #computer will block or win, but not think ahead 
        possmoves = Hash.new { [] }
        (1..9).each do |i|
          r = convert_to_row(i)
          c = convert_to_col(i)
          current_cell = cell(r,c)
          if current_cell.is_a?(Integer)
            diag1, diag2 = diagonals_from(r,c)

            possmoves[:win] = possmoves[:win] << current_cell if row(r).count(sign) == 2
            possmoves[:win] = possmoves[:win] << current_cell if col(c).count(sign) == 2
            possmoves[:win] = possmoves[:win] << current_cell if diag1.count(sign) == 2
            possmoves[:win] = possmoves[:win] << current_cell if diag2.count(sign) == 2

            possmoves[:block] = possmoves[:block] << current_cell if row(r).count(opp_sign) == 2
            possmoves[:block] = possmoves[:block] << current_cell if col(c).count(opp_sign) == 2
            possmoves[:block] = possmoves[:block] << current_cell if diag1.count(opp_sign) == 2
            possmoves[:block] = possmoves[:block] << current_cell if diag2.count(opp_sign) == 2
          end
        end
        p possmoves

        begin
          pick = possmoves[:win].first || possmoves[:block].first || rand(9)+1
        end until valid?(pick)

      when 3 #minimax
        possboards = []
        valid_moves.each do |i|
          tempboard = @grid.dup
          tempboard[i] = mark
          possboards[i] = get_score(tempboard,true,mark)  
        end
        pick = possboards.index(mark) || possboards.index(0) || possboards.index(opp_mark(mark)) 
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
      winstates << (board[3] + board[4] + board[6]).abs
      if winstates.any?{|state| state == 3}
        my_turn ? score = 1 : score = -1
      elsif !board.any?{|x| x == 0}
        score = 0
      else
        nextboards = []
        board.each_with_index do |x,i|
          if x == 0
            newboard = board.dup
            newboard[i] = opp_mark(mark)
            nextboards << newboard
          end
        end
        nextboards.map!{|bd| get_score(bd,!my_turn, opp_mark(mark))}
        #puts "nextboards scores are #{nextboards}"
        if (my_turn && mark == 1) || (!my_turn && mark == -1)
          score = nextboards.min
        else
          score = nextboards.max
        end
      end
      score
    end

    

    def game_over?

      row_i, col_i, mark = @last_move
    
      row_to_check = row(row_i)

      col_to_check = col(col_i)

      diag_left, diag_right = diagonals_from(row_i, col_i)

      [row_to_check, diag_left, diag_right, col_to_check].each do |line|
        return true if line.join.match(mark * 3)
      end

      if @turns == 9
        @turns +=1 and return true
      end

      false
    end

    def draw?
      @turns > 9
    end
  end #class Board

end #module TicTacToe

