require 'vendor/gems/environment'
require 'em-websocket'
require 'uuid'
require 'mq'

uuid = UUID.new

EventMachine::WebSocket.start(:host => "0.0.0.0", :port => 8080) do |ws|
  ws.onopen do
    puts "WebSocket opened"

    chess_q = MQ.new
    chess_q.queue(uuid.generate).bind(chess_q.fanout('chess')).subscribe do |t|
      puts "new event"
      ws.send t
    end
  end

  ws.onclose do
    puts "WebSocket closed"
  end
end
