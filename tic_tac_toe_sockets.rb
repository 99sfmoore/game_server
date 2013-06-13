module TicTacToe

  class Board
    attr_reader :turns

    def initialize()
      @grid = [[1,2,3],[4,5,6],[7,8,9]]
      @turns = 0
      @last_move = [0,0,"X"] # for debugging
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
      s = row.map {|x| " #{x} "}
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
        diag_right = [cell(row_i, col_i), cell(row_i-1, col_i+1), cell(row_i-2, col_i+2)]
      end

      [diag_left || [], diag_right || [] ]
    end

    public

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
      mark == "1" ? sign = "X" : sign = "O"
      @grid[row_i][col_i] = sign
      @last_move = [row_i, col_i, sign]
      @turns +=1
    end

    def auto_move(level,mark)
      case level
      when 1  #computer picks randomly
        puts "im in 1"
        begin
          pick = rand(9)+1
        end until valid?(pick)
      
      when 2 #computer will block or win, but not think ahead 
        puts "i'm in 2"
        possmoves = Hash.new {Array.new}
        @grid.each_with_index do |r, row|
          r.each_with_index do |cell, col|
            if cell.is_a?(Integer)
              puts "i'm looking at #{cell}"
              puts "last move is #{@last_move.last}" if @turns > 1 
              possmoves[:win] = possmoves[:win] << cell if (@grid[row-1][col] == mark && @grid[row-2][col] == mark)
              possmoves[:win] = possmoves[:win] << cell if (@grid[row][col-1] == mark && @grid[row][col-2] == mark)
              possmoves[:block] = possmoves[:block] << cell if (@grid[row-1][col] == @last_move.last && @grid[row-2][col] == @last_move.last)
              possmoves[:block] = possmoves[:block] << cell if (@grid[row][col-1] == @last_move.last && @grid[row][col-2] == @last_move.last)
              puts "at end of check"
            end
          end  
        end
        p possmoves
        begin
          puts "I'm in rand loop"
          pick = possmoves[:win].first || possmoves[:block].first ||rand(9)+1
          puts "pick is #{pick}"
        end until valid?(pick)

      else
          puts "i'm in else and level is #{level}"
      end
      puts "#{pick}"
      return pick
    end

    def game_over?
      return false if @turns < 5
      row_i, col_i, mark = @last_move
    
      row_to_check = row(row_i)

      col_to_check = col(col_i)

      diag_left, diag_right = diagonals_from(row_i, col_i)

      [row_to_check, col_to_check, diag_left, diag_right].each do |line|
        return true if line.join.match(mark * 3)
      end

      if @turns == 9
        @turns +=1 and true
      end

      false
    end

    def draw?
      @turns > 9
    end
  end #class Board

end

