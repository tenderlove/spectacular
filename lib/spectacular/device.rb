require 'spectacular/history'
require 'snmp'
require 'json'

module Spectacular
  class Device
    attr_reader :host, :history

    def initialize host, history = 10
      @host    = host
      @history = new_history history
    end

    def columns
      ["ifIndex", "ifDescr", "ifInOctets", "ifOutOctets"]
    end

    def interfaces
      manager = snmp_manager host
      interfaces = []
      manager.walk(['ifDescr']) do |row|
        interfaces << row.first.value.to_s
      end
      interfaces
    ensure
      manager.close
    end

    def monitor interval = 1
      manager = snmp_manager host

      loop do
        manager.walk(columns) do |row|
          key = row[1].value.to_s

          result = diff history.last(key), row

          yield result unless result.empty?

          history.add key, row.map(&:dup)
        end
        sleep interval
      end

    ensure
      manager.close
    end

    private
    def snmp_manager host
      SNMP::Manager.new :Host => host
    end

    Klass = Struct.new :name, :value # :nodoc:

    def diff from, to
      return [] unless from && to

      to.first(2) + from.zip(to).last(2).map { |left, right|
        diff = right.value.to_i - left.value.to_i
        Klass.new left.name, diff
      }
    end

    def new_history size
      History.new size
    end
  end
end

if __FILE__ == $0
  dev = Spectacular::Device.new '10.0.1.1'
  p dev.interfaces
  dev.monitor do |row|
    data = {
      :name      => row[1].value.to_s,
      :in_delta  => row[2].value,
      :out_delta => row[3].value,
    }

    puts "data: #{JSON.dump(data)}\n"
  end
end
