require 'bindata'

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
      skip length: 5
      byte_array :type_name
      choice :object, selection: proc {type_name.chomp("\x00")} do
        buffer_info "BufferInfo"
        message "Message"
      end

      def get
        object
      end
    end
  end
end
