require 'quassel/connection'
require 'matchmaker'
require 'helpers'

module Quassel
  class Client
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

      connection.on :message_received do |c, message|
        Case message do
          of [Quassel::RPC_CALL, '2displayMsg(Message)', _]  do
            puts Quassel::Client.format_message('%{timestamp} %{buffer.name} %{sender} %{content}', message[2])
            require 'pry'
          end
          of _ do
           p message
          end
        end
      end

      connection.connect
    end

    def self.format_message(format, message)
      hash = {}
      format.scan(/%\{([^}]+)}/) do |(key)|
        hash[key.to_sym] = key.split('.').inject(message) do |result, part|
          result.send part
        end
      end
      format % hash
    end
  end
end

