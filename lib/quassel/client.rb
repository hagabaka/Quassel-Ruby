require 'quassel/connection'
require 'helpers'
require 'eventful'

module Quassel
  class Client
    include Eventful

    def initialize(username, password, host = nil, port = nil)
      connection = Connection.new(host, port)

      connection.on :connected do
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

      connection.on :message_received do |_, message|
        fire :message_received, message
      end

      connection.connect
    end
  end
end

