require 'webrick'

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
          rw.write "retry: 100000\n"
          rw.write "data: omg lol\n"
          rw.close
        }
      end
    end
  end
end

if $0 == __FILE__
  server = WEBrick::HTTPServer.new :Port => 8080
  server.mount '/',            Spectacular::Server::Index
  server.mount '/events.json', Spectacular::Server::Events

  trap('INT') { server.shutdown }
  server.start
end
