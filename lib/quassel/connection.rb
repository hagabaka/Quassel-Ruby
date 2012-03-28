require 'QuasselTypes'
require 'quassel/helpers'
require 'eventful'

module Quassel
  SYNC = 1
  RPC_CALL = 2
  INIT_REQUEST = 3
  INIT_DATA = 4
  HEART_BEAT = 5
  HEART_BEAT_REPLY = 6

  # Connection to a Quassel core, or in the proxy script, client
  class Connection
    include Eventful 

    DEFAULT_HOST = '127.0.0.1'
    DEFAULT_PORT = 4242

    def initialize(host = nil, port = nil, socket = nil)
      @host = host ? host : DEFAULT_HOST
      @port = port ? port : DEFAULT_PORT
      @socket = socket || Qt::TcpSocket.new

      @expected_length = nil

      @socket.connect SIGNAL(:connected) do
        fire :connected
      end

      @socket.connect SIGNAL(:readyRead) do
        until @socket.bytes_available < (@expected_length || 4)
          # each message is a QVariant map or list, and prefixed by its length as uint32
          if @expected_length
            # received the length, get the message
            receive_data(@expected_length) do |data|
              message = Quassel.unserialize_variant(data)
              @expected_length = nil
              fire :message_received, message, data
            end 
          else
            # need a length
            receive_data(4) do |data|
              @expected_length = data.unpack('L>').first
            end
          end
        end
      end
    end

    # send a message to the peer
    def transmit(message)
      transmit_serialized Quassel.qt_serialize(Qt::Variant.new(message))
    end

    # send an already serialized block of data to the peer
    def transmit_serialized(block)
      length = Quassel.qt_serialize(block.length)
      @socket.write length
      @socket.write block
    end

    # connect to the peer
    def connect
      @socket.connect_to_host(@host, @port)
    end

    # receive exactly the specified number of bytes of data from @socket if they exist,
    # and yield the data to block when received
    def receive_data(length, &block)
      if @socket.bytes_available >= length
        data = "\0" * length
        @socket.read_data(data, length)
        yield data
      end
    end
  end
end
