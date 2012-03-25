module Spectacular
  class SizedList
    include Enumerable

    def initialize size
      @size = size
      @list = []
    end

    def << item
      x = @list << item
      while @list.size > @size
        @list.shift
      end
      x
    end

    def each &block
      @list.each(&block)
    end

    def last
      @list.last
    end

    def length
      @list.length
    end
  end
end
