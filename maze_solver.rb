require 'byebug'

class Maze
  attr_reader :map, :start, :end, :path

  def initialize(map)
    @map   = map
    @start = start_position
    @end   = end_position
  end

  def [](row, col)
    @map[row][col]
  end

  def []=(row, col, mark)
    @map[row][col] = mark
  end

  def each_with_pos(&prc)
    @map.each_with_index { |line, row|
      line.each_with_index { |el,  col| prc.call(el, [row, col]) } }
  end

  def start_position
    strt_pos = nil
    each_with_pos { |el, pos| strt_pos = pos if el == "S" }

    Position.new(*strt_pos)
  end

  def end_position
    end_pos = nil
    each_with_pos { |el, pos| end_pos = pos if el == "E" }

    Position.new(*end_pos)
  end

  def record(path)
    path.each { |pos| self.[]=(*(pos.get), :X) if self[*(pos.get)] == " " }
  end

  def edge?(pos)
    self[*(pos.get)] == "*"
  end

  def space?(pos)
    self[*(pos.get)] == " "
  end

  def end?(pos)
    self[*(pos.get)] == "E"
  end

  def draw
    @map.each do |row|
      row.each { |el| print el }
      print "\n"
    end

    nil
  end
end

class Explorer
  attr_reader :maze, :paths

  DIRECTIONS  = [:up, :down, :left, :right]

  def initialize(maze)
    @maze     = maze
    @paths    = [[@maze.start]]
  end

  def explore(path = @paths[0].dup)
    spaces, end_of_maze = check_surroundings(path) #returns positions of empty spaces

    return found_end(path << end_of_maze) if end_of_maze

    spaces.each do |space|
      new_path  = path.dup
      new_path  << space

      @paths    << new_path
    end

    delete_longer_paths

    @paths.shift

    explore(@paths.first)
  end

  def check_surroundings(path)
    end_point   = path.last
    spaces      = []
    end_of_maze = nil

    DIRECTIONS.each do |dir|
      spaces      << end_point.next_(dir) if can_continue?(path, dir)
      end_of_maze =  end_point.next_(dir) if @maze.end?(end_point.next_(dir))
    end

    [spaces, end_of_maze]
  end

  def found_end(path)
    @maze.record(path)
    @maze.draw
    puts "Found end."
    exit
  end

  def can_continue?(path, dir)
    @maze.space?(path.last.next_(dir)) &&
    !path.include?(path.last.next_(dir))
  end

  def is_longer?(check_path)
    @paths.each do |path|
      return true if check_path.last.get == path.last.get &&
                     check_path.length >= path.length &&
                     check_path != path
    end

    false
  end

  def delete_longer_paths
    @paths.delete_if { |path| is_longer?(path) }
  end
end

class Position
  attr_reader :row, :column, :direction

  def initialize(row, column)
    @row    = row
    @column = column
  end

  def get
    [@row, @column]
  end

  def next_(dir)
    row = @row
    col = @column

    case dir
    when :up
      row -= 1
    when :down
      row += 1
    when :right
      col += 1
    when :left
      col -= 1
    end

    Position.new(row, col)
  end
end

if __FILE__ == $PROGRAM_NAME
  map    = []
  File.open(ARGV[0]).each_line { |line| map << line.chomp.split(//) }

  maze   = Maze.new(map)
  nathan = Explorer.new(maze)
  
  maze.draw
  nathan.explore
end
