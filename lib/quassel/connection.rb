require 'QuasselTypes'
require 'quassel/helpers'

module Quassel
  # Connection to Quassel core
  class Connection
    DEFAULT_HOST = '127.0.0.1'
    DEFAULT_PORT = 4242
    def initialize(host = nil, port = nil)
      @host = host ? host : DEFAULT_HOST
      @port = port ? port : DEFAULT_PORT
      @socket = Qt::TcpSocket.new
      @expected_length = nil
    end

    # send a QVariant map message to core, symbol keys are converted to strings
    def transmit(message)
      map = Quassel.map_keys(message, &:to_s)
      block = Quassel.qt_serialize(Qt::Variant.new(map))
      length = Quassel.qt_serialize(block.length)
      @socket.write length
      @socket.write block
    end

    # yield to given block when socket is connected
    def when_connected(&block)
      @socket.connect SIGNAL(:connected), &block
    end

    REQUEST_TYPES = [nil, :sync, :rpc_call, :init_request, :init_data, :heart_beat,
                     :heart_beat_reply]
    # yield message to given block when a message is received
    def when_message_received(&block)
      @socket.connect SIGNAL(:readyRead) do
        # each message is a QVariant map or list, and prefixed by its length as uint32
        if @expected_length
          # received the length, get the message
          receive_data(@expected_length) do |data|
            message = Quassel.unserialize_variant(data)
            if message.is_a? Array
              message[0] = REQUEST_TYPES[message[0]]
            end
            @expected_length = nil
            block.call(message)
          end 
        else
          # need a length
          receive_data(4) do |data|
            @expected_length = data.unpack('L>').first
          end
        end
      end
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
