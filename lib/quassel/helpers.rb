
require 'Qt'
require 'quassel/serialization'

module Quassel
  class << self
    # serialize data using Qt
    def qt_serialize(data)
      block = Qt::ByteArray.new
      writer = Qt::DataStream.new(block, Qt::IODevice::WriteOnly)
      writer << data
      block
    end

    # print Qt object using QDebug. p() for Qt objects
    def qt_debug(object)
      buffer = Qt::Buffer.new
      buffer.open Qt::Buffer::WriteOnly
      debug = Qt::Debug.new(buffer)
      debug << object
      buffer.close
      buffer.open Qt::Buffer::ReadOnly
      puts buffer.data.to_s
    end

    # recursively convert a Qt::Variant (possibly container) to ruby value
    def ruby_value(object)
      case object
      when Qt::Variant
        type_name = object.type_name
        if %w[BufferInfo Message Identity
              NetworkId BufferId MsgId IdentityId Network::Server].include? type_name
          if Serialization.const_defined? type_name
            data = qt_serialize(object).data
            Serialization::Variant.read data
          else
            object
          end
        else
          ruby_value(object.value)
        end
      when Hash
        result = {}
        object.each_pair {|key, value| result[ruby_value(key)] = ruby_value(value)}
        result
      when Array
        object.map {|i| ruby_value(i)} 
      else
        object
      end
    end
  end
end
