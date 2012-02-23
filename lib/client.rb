require 'connection'

module Quassel
  class Client
    def initialize(username, password, host = nil, port = nil)
      connection = Connection.new(host, port)

      connection.when_connected do
        connection.transmit \
          MsgType: 'ClientInit',
          ClientDate: Time.now.strftime('%^b %d %Y %H:%M:%S'),
          UseSsl: false,
          ClientVersion: 'v0.6.1',
          UseCompression: false,
          ProtocolVersion: 10

        connection.transmit \
          MsgType: 'ClientLogin',
          User: username,
          Password: password
      end

      connection.when_message_received do |message|
        p message
      end

      connection.connect
    end
  end
end

