class Jsonable
  #to turn 2D game_board into jsonable hash

  def initialize(two_D_array = [])
    two_D_array.each_with_index do |col, i|
      instance_variable_set("@col#{i}",col)
    end
  end

  def ready_for_json
    my_hash = {}
    (0..6).each do |i|
      my_hash[i] = instance_variable_get("@col#{i}")
    end
    my_hash
  end

  def from_json!(my_hash)
    my_hash.each do |k,v|
      instance_variable_set("@col#{k}",v)
    end
    self
  end

  def two_d_array
    two_d = []
    (0..6).each_with_index do |i|
      two_d << instance_variable_get("@col#{i}")
    end
    two_d
  end

end