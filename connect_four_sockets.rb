require 'colored'

module ConnectFour 

  class Board

    attr_accessor :turns, :grid #for cloning purposes.  Better way to do this?

    def initialize
      @grid = Array.new(7){[]}
      @turns = 0
    end

    def clone  #There has to be a better way to do this
      tempboard = Board.new
      @grid.each_with_index do |c, i|
        tempboard.grid[i] = c.dup
      end
      tempboard.turns = @turns
      tempboard
    end

    def possible_moves(mark)
      possmoves = Hash.new { [] }
      (1..7).each do |m|
        puts "looking at #{m}"
        tempboard = self.clone
        tempboard.make_move(m,mark)

        if tempboard.game_over?
          possmoves[:win] = possmoves[:win] << m
        else
          tempboard = self.clone
          tempboard.make_move(m,opp_mark(mark))
          if tempboard.game_over?
            possmoves[:block] = possmoves[:block] << m
          end
        end
      end
      possmoves
    end

    def think(mark)
      (1..7).each do |m|
        puts "looking at #{m}"
        tempboard = self.clone
        tempboard.make_move(m,mark)

        if tempboard.game_over?
          possmoves[:win] = possmoves[:win] << m
        else
          tempboard = self.clone
          tempboard.make_move(m,opp_mark(mark))
          if tempboard.game_over?
            possmoves[:block] = possmoves[:block] << m
          else
            tempboard = self.clone
            tempboard.make_move(m,mark)
            possmoves = tempboard.think(opp_mark(mark))
          end
        end
      end
      possmoves
    end


    def row(i)  #returns array of entire ith row
      @grid.map { |col| col[i]}
    end

    def rows #returns 2D array of all rows
      5.downto(0).map {|i| row(i)}
    end

    def col(i) #returns array of entire ith col
      @grid[i]
    end

    def cols #returns 2D array of all cols
      @grid
    end
     
    def cell(col_i, row_i) #returns value at a given point in the grid
      @grid[col_i][row_i] 
    end

    def opp_mark(mark)
      mark == 1 ? 2 : 1
    end

    def diagonals_from(col_i, row_i)
      diag_left = []
      diag_right = []

      (0..5).each do |row_offset|
        col1_i = (col_i +row_i) - row_offset
        col2_i = (col_i - row_i) + row_offset
        diag_left << cell(col1_i, row_offset) if col1_i >= 0 && col1_i <= 6
        diag_right << cell(col2_i, row_offset) if col2_i >= 0 && col2_i <= 6
      end

      [diag_left, diag_right]
    end

    def display_row(row)
      s = row.map do |cell|
        if cell.nil?
          "   "
        elsif cell == 1
          " @ ".red
        else
          " @ ".black
        end
      end
      "|".blue + s.join("|".blue) + "|".blue
    end

    def display
      row_sep = ("+---"*7+"+").blue
      rows_string = rows.map {|r| display_row(r) + "\n"}.join(row_sep + "\n")
      legend = "  1   2   3   4   5   6   7"
      row_sep + "\n" + rows_string + row_sep + "\n" + legend + "\n"
    end

    def make_move(move,mark)
      @grid[move-1] << mark
      @last_move = [move-1,mark.to_s]
      @turns +=1
      puts "turns is #{@turns}"
    end

    def valid?(move)
      !(move < 1 || move > 7 || @grid[move-1].size >=6)
    end

    def auto_move(level,mark)
      case level
      when 1 #computer picks randomly
        begin
          pick = rand(7)+1
        end until valid?(pick)

      when 2 #computer will block or win, but not think ahead
        possmoves = possible_moves(mark)
        puts "possmoves is #{possmoves}"
        begin
          pick = possmoves[:win].first || possmoves[:block].first || rand(7)+1
        end until valid?(pick)

      when 3 # computer thinks ahead
        possmoves = possible_moves(mark)
        begin
          pick = possmoves[:win].first || possmoves[:block].first || think(mark)
        end until valid?(pick)
      end

      pick
    end

    def game_over?
      
      col_i, color = @last_move
      col_to_check = col(col_i)

      row_i = col_to_check.size - 1
      row_to_check = row(row_i)

      diag_left, diag_right = diagonals_from(col_i, row_i)

      [col_to_check, row_to_check, diag_left, diag_right].each do |line|
        return true if nils_to_spaces(line).join.match(color * 4)
      end

      if @turns == 42
        @turns +=1 and true
      end

      false
    end

    def draw?
      @turns > 42
    end

    private

    def nils_to_spaces(arr)
      arr.map { |x| x || " " }
    end

  end # class Board

end #module ConnectFour