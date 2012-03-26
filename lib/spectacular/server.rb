require 'webrick'
require 'spectacular'
require 'json'

Thread.abort_on_exception = true

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
      def do_GET request, response
        response.status = 200
        response['Content-Type'] = 'text/event-stream'
        rd, rw = IO.pipe

        response.body = rd

        Thread.new {
          begin
            ip = ENV['ROUTER'] || '10.0.1.1'
            dev = Spectacular::Device.new ip

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

if $0 == __FILE__
  server = WEBrick::HTTPServer.new :Port => 8080, :OutputBufferSize => 256

  server.mount '/',            Spectacular::Server::Index
  server.mount '/events.json', Spectacular::Server::Events

  trap('INT') { server.shutdown }
  server.start
end
