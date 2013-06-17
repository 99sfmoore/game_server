require 'colored'

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
      sign = convert_mark(mark)
      @grid[row_i][col_i] = sign
      @last_move = [row_i, col_i, sign]
      @turns +=1
      puts "#{@turns}"
    end

    def auto_move(level,mark)
      sign = convert_mark(mark)
      opp_sign = @last_move.last
      case level
      when 1  #computer picks randomly
        puts "im in 1"
        begin
          pick = rand(9)+1
        end until valid?(pick)
      
      when 2 #computer will block or win, but not think ahead 
        puts "i'm in 2"
        possmoves = Hash.new { [] }
        (1..9).each do |i|
          puts "looking at #{i}"
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
          puts "I'm in rand loop"
          pick = possmoves[:win].first || possmoves[:block].first || 5 || rand(9)+1
          puts "pick is #{pick}"
        end until valid?(pick)

      when 3 #implement min max

      else
          puts "i'm in else and level is #{level}"
      end
      puts "#{pick}"
      return pick
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

end

