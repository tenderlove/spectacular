require 'spectacular/sized_list'

module Spectacular
  class History
    def initialize size = 10
      @groups = Hash.new { |h,k|
        h[k] = new_list size
      }
    end

    def add k, v
      @groups[k] << v
    end

    def last k, len = nil
      if len
        @groups[k].last len
      else
        @groups[k].last
      end
    end

    def [] k
      @groups[k].to_a
    end

    private
    def new_list size
      SizedList.new size
    end
  end
end
