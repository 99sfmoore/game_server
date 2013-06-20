require 'colored'
require 'json'

module TicTacToe

  class Board
    attr_reader :turn 

    def initialize(grid = nil, turns = nil)
      @grid = grid || [[1,2,3],[4,5,6],[7,8,9]]
      @turns = turns || 0
    end

    def clone
      new_grid = rows.map {|r| r.dup}
      nb = Board.new(new_grid, @turns)
      nb
    end

    
    private

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

    def convert_mark(mark)
       mark == 1 ? "X" : "O"
    end

    def opp_mark(mark)
      mark == 1 ? mark = 2 : mark = 1
    end

    def num_to_grid(num)
      r = convert_to_row(num)
      c = convert_to_col(num)
      result_cell = cell(r,c)
      result_cell
    end

    def valid_moves
      moves = []
      (1..9).each do |i|
        current_cell = num_to_grid(i)
        moves << i if current_cell.is_a?(Integer)
      end
      moves
    end


    public

    def write_tictax #needs to create actual tictax hash, not just board
      board = @grid.flatten.map do |i|
        if i.is_a?(Integer)
          0
        elsif i == "X"
          1
        else
          -1
        end
      end
      board_hash = {"board" => board}
    end

    def read_tictax(board) # to be finished
      board.each_with_index do |cell, i| 
        if cell == 1 
          @grid[convert_to_row(i+1)][convert_to_col(i+1)] = "X"
          #num_to_grid(i+1) = "X"
        elsif cell == -1
          #num_to_grid(i+1) = "O"
          @grid[convert_to_row(i+1)][convert_to_col(i+1)] = "O"
        end
      end
      @turns +=1 unless board.all?{|x| x == 0}
    end



    def display 
      row_sep = "+---"*3+"+\n"
      rows_string = rows.map { |r| display_row(r)}.join("\n"+row_sep)
      row_sep + rows_string + "\n" + row_sep
    end

    def valid?(move)
      return false if move < 1 || move > 9
      row_i = convert_to_row(move) 
      col_i = convert_to_col(move)
      cell(row_i,col_i).is_a?(Integer)
    end

    def make_move(move,mark)
      row_i = convert_to_row(move)
      col_i = convert_to_col(move)
      sign = convert_mark(mark)
      @grid[row_i][col_i] = sign
      @last_move = [row_i, col_i, sign]
      @turns +=1
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
          tempboard = self.clone
          tempboard.make_move(i,mark)
          possboards[i] = tempboard.get_score(true,mark)  
        end
        pick = possboards.index(1) || possboards.index(0) || possboards.index(-1) 
      end
      return pick
    end

    def get_score(my_turn,mark)
      if game_over?
        if draw?
          score = 0
        elsif my_turn
          score = 1
         else
           score = -1
         end

      else
        nextboards = []
        valid_moves.each do |i|
          tempboard = self.clone
          tempboard.make_move(i,opp_mark(mark))
          nextboards << tempboard
        end
        nextboards.map!{|board| board.get_score(!my_turn, opp_mark(mark))}
        puts "nextboards scores are #{nextboards}"
        if my_turn
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

