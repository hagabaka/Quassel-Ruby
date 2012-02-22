module Quassel
  # serialize data using Qt
  def qt_serialize(data)
    block = Qt::ByteArray.new
    writer = Qt::DataStream.new(block, Qt::IODevice::WriteOnly)
    writer << data
    block
  end

  # recursively convert a Qt::Variant (possibly container) to ruby value
  def ruby_value(object)
    case object
    when Qt::Variant
      ruby_value(object.value)
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
