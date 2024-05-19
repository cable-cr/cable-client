require "json"
require "http/web_socket"

class CableClient
  VERSION = "0.1.0"

  @ws : HTTP::WebSocket
  property? connected : Bool = false
  property channel : String

  property connected_callback : _ -> _
  property disconnected_callback : _ -> _
  property message_callback : String -> _

  def initialize(url : String, @channel : String)
    @ws = HTTP::WebSocket.new(url, headers: HTTP::Headers{"Sec-WebSocket-Protocol" => "actioncable-v1-json"})
    @ws.send({
      command:    "subscribe",
      identifier: {channe: @channel}.to_json,
    }.to_json)
    @connected = true
    @ws.on_close do |_|
      disconnected_callback.call
    end
    @ws.on_message do |data|
      message_callback.call(data)
    end
  end

  def connected(&)
    self.connected_callback = ->{
      yield
    }
  end

  def disconnected(&)
    self.disconnected_callback = ->{
      yield
    }
  end

  def received(& : String -> _)
    self.message_callback = ->(data : String) {
      yield data
    }
  end

  def perform(action : String, data : Hash(String, JSON::Any))
    response = {
      "command"    => "message",
      "identifier" => {channe: @channel}.to_json,
      "data"       => {
        "action": JSON::Any.new(action),
      }.merge(data).to_json,
    }.to_json
    @ws.send(response)
  end
end
