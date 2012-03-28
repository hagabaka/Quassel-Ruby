require 'quassel/connection'

Quassel::CLIENT = Quassel::Connection.new.tap do |client|
  client.on(:connected) do
    transmit_map \
      MsgType: 'ClientInit',
      ClientDate: Time.now.strftime('%^b %d %Y %H:%M:%S'),
      UseSsl: false,
      ClientVersion: 'v0.6.1',
      UseCompression: false,
      ProtocolVersion: 10

    transmit_map \
      MsgType: 'ClientLogin',
      User: Quassel::CONFIG[:username],
      Password: Quassel::CONFIG[:password]
  end

  client.connect
end

# send a hash message as QMap with symbol keys converted to strings
def transmit_map(message)
  Quassel::CLIENT.transmit Quassel.map_keys(message, &:to_s)
end

