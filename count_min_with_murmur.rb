require 'murmurhash3/pure_ruby'

class CountMinSystem

  #Holds a hash function and the corresponding counters
  class CountMinStorage
    include MurmurHash3::PureRuby32
    def initialize(width, seed)
      @width = width
      @counts = Array.new(@width){0}
      @seed = seed
    end

    def run_hash(str)
      murmur3_32_str_hash(str, @seed)
    end

    def add(item, quantity)
      hashed_value = run_hash(item) % @width
      @counts[hashed_value] += quantity
    end

    def get_count(item)
      hashed_value = run_hash(item) % @width
      @counts[hashed_value]
    end
  end

  class CountMin
    attr_reader :storage_instances
    def initialize(width, hash_seeds)
      @storage_instances = hash_seeds.map{|h| CountMinStorage.new(width, h)}
    end

    def add(item, quantity=1)
      @storage_instances.each do |instance|
        instance.add(item, quantity)
      end
    end

    def get_count(item)
      @storage_instances.map{|instance| instance.get_count(item)}.min
    end
  end

  attr_reader :depth
  def initialize(epsilon:, delta:, hash_seed_max: 1_000_000_000)
    @epsilon = epsilon
    @delta = delta
    @width = (Math::E/@epsilon).ceil
    @depth = Math.log(1.0/@delta).ceil
    @hash_seeds = Array.new(@depth){hash_seed_max}
  end

  #Creates a new CountMin
  def create_new_cm
    CountMin.new(@width, @hash_seeds)
  end

  #Gets the count of an item given all of the CountMins that have been run on subsets
  def self.get_count(cm_array, depth, item)
    totals = []
    depth.times do |d|
      storage_instances = cm_array.map{|cm| cm.storage_instances[d]}
      total = 0
      storage_instances.each do |storage_instance|
        total += storage_instance.get_count(item)
      end
      totals << total
    end
    totals.min
  end
end
