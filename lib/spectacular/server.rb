require 'webrick'
require 'spectacular'
require 'json'

module Spectacular
  module Server
    INDEX = File.read File.expand_path '../index.html', __FILE__

    class Index < WEBrick::HTTPServlet::AbstractServlet
      def initialize server, name
        super server

        @name = name
      end

      def do_GET request, response
        body = INDEX % [@name]

        response.status = 200
        response['Content-Type'] = 'text/html'
        response.body = body
      end
    end

    class Events < WEBrick::HTTPServlet::AbstractServlet

      def initialize server, router, interfaces
        super server

        @router = router
        @interface_args = interfaces
      end

      def do_GET request, response
        response.status = 200
        response.chunked = true
        response['Content-Type'] = 'text/event-stream'
        rd, rw = IO.pipe

        response.body = rd

        Thread.new {
          begin
            dev = Spectacular::Device.new @router, @interface_args

            rw.write "event: interfaces\n"
            rw.write "data: #{JSON.dump(dev.interfaces)}\n\n"
            rw.flush

            dev.monitor do |row|
              data = {
                :interface => row[1].value.to_s,
                :in_delta  => row[2].value,
                :out_delta => row[3].value,
              }

              rw.write "event: update\n"
              rw.write "data: #{JSON.dump(data)}\n\n"
              rw.flush
            end
          ensure
            rw.close
          end
        }
      end
    end
  end
end
