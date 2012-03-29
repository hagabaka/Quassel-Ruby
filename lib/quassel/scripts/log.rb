require 'quassel/scripts/client'

require 'case'
require 'Qt'

DISPLAY_MESSAGE = Qt::ByteArray.new('2displayMsg(Message)')

Quassel::CORE.on :message_received do |_, message|
  if Case[Quassel::RPC_CALL, DISPLAY_MESSAGE, Case::Any] === message
    m = message[2]
    puts "#{m.timestamp} #{m.buffer.name} #{m.sender} #{m.content}"
  end
end

