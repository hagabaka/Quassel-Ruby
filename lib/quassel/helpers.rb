
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

    # unserialize a QVariant from given string, and return its recursive value
    def unserialize_variant(string)
      variant = Qt::Variant.new
      reader = Qt::DataStream.new(Qt::ByteArray.new(string))
      reader >> variant
      ruby_value variant
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

        if %w[BufferInfo Message Identity Network::Server
              NetworkId BufferId MsgId IdentityId
              ushort QChar].include? type_name
          begin
            Serialization::Variant.read qt_serialize(object).data
          rescue IndexError
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

    # return a hash whose keys are results of calling block on keys of given hash
    def map_keys(hash, &block)
      hash.inject({}) do |result, (key, value)|
        result.merge({yield(key) => value})
      end
    end
  end
end
