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

  # Connection to Quassel core
  class Connection
    include Eventful 

    DEFAULT_HOST = '127.0.0.1'
    DEFAULT_PORT = 4242
    def initialize(host = nil, port = nil)
      @host = host ? host : DEFAULT_HOST
      @port = port ? port : DEFAULT_PORT
      @socket = Qt::TcpSocket.new
      @expected_length = nil

      @socket.connect SIGNAL(:connected) do
        fire :connected
      end

      @socket.connect SIGNAL(:readyRead) do
        # each message is a QVariant map or list, and prefixed by its length as uint32
        if @expected_length
          # received the length, get the message
          receive_data(@expected_length) do |data|
            message = Quassel.unserialize_variant(data)
            @expected_length = nil
            fire :message_received, message
          end 
        else
          # need a length
          receive_data(4) do |data|
            @expected_length = data.unpack('L>').first
          end
        end
      end
    end

    # send a QVariant map message to core, symbol keys are converted to strings
    def transmit(message)
      map = Quassel.map_keys(message, &:to_s)
      block = Quassel.qt_serialize(Qt::Variant.new(map))
      length = Quassel.qt_serialize(block.length)
      @socket.write length
      @socket.write block
    end

    # connect to core
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
