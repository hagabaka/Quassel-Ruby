require 'bindata'
require 'caseconverter'
require 'Qt'

module Quassel
  module Serialization
    class ByteArray < BinData::Primitive
      endian :big
      uint32 :len
      string :content, read_length: :len

      def get
        content
      end
    end

    class Utf16String < BinData::String
      def snapshot
        super.force_encoding 'UTF-16BE'
      end
    end

    class QtString < BinData::Primitive
      endian :big
      uint32 :len
      utf16_string :content, read_length: :len

      def get
        content.encode 'UTF-8'
      end
    end

    class QtStringList < BinData::Primitive
      endian :big
      uint32 :len
      array :list, initial_length: :len, type: :qt_string
      def get
        list
      end
    end

    class BufferInfo < BinData::Record
      class Type < BinData::Primitive
        endian :big
        uint16 :number
        def get
          { 0x00 => :invalid,
            0x01 => :status,
            0x02 => :channel,
            0x04 => :query,
            0x08 => :group }[number]
        end
      end

      endian :big
      uint32 :id
      uint32 :network_id
      type :type
      uint32 :group_id
      byte_array :name
    end

    class Timestamp < BinData::Primitive
      endian :big
      uint32 :seconds
      def get
        Time.at seconds
      end
    end

    class Message < BinData::Record
      class Type < BinData::Primitive
        endian :big
        uint32 :number
        def get
          { 0x00001 => :plain,
            0x00002 => :notice,
            0x00004 => :action,
            0x00008 => :nick,
            0x00010 => :mode,
            0x00020 => :join,
            0x00040 => :part,
            0x00080 => :quit,
            0x00100 => :kick,
            0x00200 => :kill,
            0x00400 => :server,
            0x00800 => :info,
            0x01000 => :error,
            0x02000 => :day_change,
            0x04000 => :topic,
            0x08000 => :netsplit_join,
            0x10000 => :netsplit_quit,
            0x20000 => :invite }[number]
        end
      end

      endian :big
      uint32 :message_id
      timestamp :timestamp
      type :type
      uint8 :flags
      buffer_info :buffer
      byte_array :sender
      byte_array :content
    end

    class Variant < BinData::Primitive
      endian :big
    end

    # This is serialized as a QMap<QString, QVariant>
    class Identity < BinData::Primitive
      endian :big
      uint32 :len
      array :pairs, initial_length: :len do
        qt_string :name
        variant :object
      end
      def get
        result = {}
        pairs.each do |pair|
          result[pair.name] = pair.object
        end
        result
      end
    end

    class UserType < BinData::Primitive
      endian :big
      byte_array :type_name
      choice :object, selection: proc {type_name.chomp("\x00")} do
        %w[BufferId MsgId NetworkId IdentityId].each do |name|
          uint32 name
        end
        %w[BufferInfo Message Identity].each do |name|
          send CaseConverter.to_underscore_case(name), name
        end
      end

      def get
        object
      end
    end

    class Variant < BinData::Primitive
      endian :big
      uint32 :type
      uint8 :flags

      choice :object, selection: :type do
        uint32 Qt::Variant::Int.to_i
        uint8 Qt::Variant::Bool.to_i
        qt_string Qt::Variant::String.to_i
        qt_string_list Qt::Variant::StringList.to_i
        user_type Qt::Variant::UserType.to_i
      end

      def get
        object
      end
    end
  end
end
