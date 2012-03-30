require 'spectacular/history'
require 'snmp'
require 'json'

module Spectacular
  class Device
    attr_reader :host, :history

    def initialize host, history = 10, interface_args
      @host    = host
      @history = new_history history
      @interface_args = interface_args
    end

    def columns
      ["ifIndex", "ifDescr", "ifInOctets", "ifOutOctets"]
    end

    def interfaces
      manager = snmp_manager host
      if @interface_args.empty?
        interfaces = []
        manager.walk(['ifDescr']) do |row|
          interfaces << row.first.value.to_s
        end
        interfaces
      else
        @interface_args
      end
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
