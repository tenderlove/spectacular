require 'spectacular/history'
require 'snmp'
require 'json'

module Spectacular
  class Device
    attr_reader :host, :history

    COLUMNS = %w[
      ifIndex

      ifOperStatus

      ifDescr
      ifPhysAddress

      ifInOctets
      ifOutOctets
    ]

    def initialize host, history = 10, interface_args
      @host    = host
      @history = new_history history
      @interface_args = interface_args
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
        manager.walk(COLUMNS) do |row|
          next if row[1].value == 2 # down

          key = row[2].value.to_s

          result = diff history.last(key), row

          unless result.empty? then
            event = {
              :interface => key,
              :title     => interface_name(key, row[3].value),
              :in_delta  => result[2].value.to_i,
              :out_delta => result[3].value.to_i,
            }

            yield event
          end

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

    def interface_name descr, address
      mac = unless address.empty? then
              address = address.unpack('H*').first
              address.scan(/../).join ':'
            end

      [descr, mac].compact.join ' - '
    end

    def new_history size
      History.new size
    end
  end
end
