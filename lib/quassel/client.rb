require 'quassel/connection'
require 'helpers'
require 'eventful'

module Quassel
  class Client
    include Eventful

    attr_reader :connection
    def initialize(username, password, host = nil, port = nil)
      @connection = Connection.new(host, port)

      @connection.on :connected do
        transmit_map \
          MsgType: 'ClientInit',
          ClientDate: Time.now.strftime('%^b %d %Y %H:%M:%S'),
          UseSsl: false,
          ClientVersion: 'v0.6.1',
          UseCompression: false,
          ProtocolVersion: 10

        transmit_map \
          MsgType: 'ClientLogin',
          User: username,
          Password: password
      end

      @connection.on :message_received do |_, message|
        fire :message_received, message
      end

      connection.connect
    end

    # send a hash message as QMap with symbol keys converted to strings
    def transmit_map(message)
      @connection.transmit Quassel.map_keys(message, &:to_s)
    end
  end
end

