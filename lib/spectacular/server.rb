require 'webrick'
require 'spectacular'
require 'json'

module Spectacular
  module Server
    dir = File.dirname __FILE__
    INDEX = File.read File.expand_path File.join dir, 'index.html'

    class Index < WEBrick::HTTPServlet::AbstractServlet
      def do_GET request, response
        response.status = 200
        response['Content-Type'] = 'text/html'
        response.body = INDEX
      end
    end

    class Events < WEBrick::HTTPServlet::AbstractServlet

      def initialize server, router
        super server

        @router = router
      end

      def do_GET request, response
        response.status = 200
        response['Content-Type'] = 'text/event-stream'
        rd, rw = IO.pipe

        response.body = rd

        Thread.new {
          begin
            dev = Spectacular::Device.new @router

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
