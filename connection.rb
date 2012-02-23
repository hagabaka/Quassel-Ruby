require './ext/QuasselTypes'

module Quassel
  # Connection to Quassel core
  class Connection
    def initialize(host = '127.0.0.1', port = 4242)
      @host = host
      @port = port
      @socket = Qt::TcpSocket.new
      @expected_length = nil
    end

    # send a QVariant map message to core, symbol keys are converted to strings
    def transmit(message)
      map = message.inject({}) do |result, (key, value)|
        result.merge({key.to_s => value})
      end

      block = Helper.qt_serialize(Qt::Variant.new(map))
      length = Helper.qt_serialize(block.length)
      @socket.write length
      @socket.write block
    end

    # yield to given block when socket is connected
    def when_connected(&block)
      @socket.connect SIGNAL(:connected), &block
    end

    # yield message to given block when a message is received
    def when_message_received(&block)
      @socket.connect SIGNAL(:readyRead) do
        # each message is a QVariant map or list, and prefixed by its length as uint32
        if @expected_length
          # received the length, get the message
          receive_data(@expected_length) do |data|
            #variant = Qt::Variant.new
            #reader = Qt::DataStream.new(Qt::ByteArray.new(data))
            #reader >> variant
            #message = Helper.ruby_value(variant)
            message = QuasselTypes.unserialize(data)
            p data
            p @expected_length
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

    module Helper
      class << self
        # serialize data using Qt
        def qt_serialize(data)
          block = Qt::ByteArray.new
          writer = Qt::DataStream.new(block, Qt::IODevice::WriteOnly)
          writer << data
          block
        end

        # deeply convert a Qt::Variant (possibly container) to ruby value
        def ruby_value(object)
          case object
          when Qt::Variant
            ruby_value(object.value)
          when Hash
            result = {}
            object.each_pair {|key, value| result[ruby_value(key)] = ruby_value(value)}
            result
          when Array
            object.map {|item| ruby_value(item)} 
          else
            object
          end
        end
      end
    end
  end
end
