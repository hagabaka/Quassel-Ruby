require 'Qt'

clients = []
core = Quassel::Client::INSTANCE.connection

server = Qt::TcpServer.new
server.listen Qt::HostAddress.new(Qt::HostAddress::Any), 4243

server.connect SIGNAL(:newConnection) do
  socket = server.nextPendingConnection
  client = Quassel::Connection.new(nil, nil, socket)
  clients << client
  client.on :message_received do |_, message, serialized|
    puts "From a client: #{message.inspect}"
    core.transmit_serialized serialized
  end
end

core.on :message_received do |_, message, serialized|
  #puts "From core: #{message.inspect}"
  clients.each do |client|
    client.transmit_serialized serialized 
  end
end

