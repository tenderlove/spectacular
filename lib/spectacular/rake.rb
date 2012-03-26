require 'rake'
require 'spectacular/server'

namespace :spectacular do
  desc 'start the spectacular server'
  task :server do
    server = WEBrick::HTTPServer.new :Port => 8080, :OutputBufferSize => 256

    server.mount '/',            Spectacular::Server::Index
    server.mount '/events.json', Spectacular::Server::Events

    trap('INT') { server.shutdown }
    server.start
  end
end
