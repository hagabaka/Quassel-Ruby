#include <ruby.h>
#include <ruby/encoding.h>
#include <QByteArray>
#include <QDataStream>
#include <QString>
#include <QDebug>

#include "types.h"
#include "message.h"
#include "network.h"
#include "identity.h"

VALUE QuasselTypes;
extern "C" {
  void Init_QuasselTypes();
}

VALUE qt_compress(VALUE self, VALUE data)
{
  Check_Type(data, T_STRING);
  QByteArray byte_array = qCompress((const uchar*)RSTRING_PTR(data), RSTRING_LEN(data));
  size_t size = byte_array.size();
  char* result = (char*)calloc(size, sizeof(char));
  memcpy(result, byte_array.data(), size);
  return rb_str_new(result, size); 
}

VALUE qt_uncompress(VALUE self, VALUE data)
{
  Check_Type(data, T_STRING);

  QByteArray byte_array = qUncompress((const uchar*)RSTRING_PTR(data), RSTRING_LEN(data));
  size_t size = byte_array.size();
  char* result = (char*)calloc(size, sizeof(char));
  memcpy(result, byte_array.data(), size);
  return rb_str_new(result, size); 
}

void Init_QuasselTypes() {
  // Copied from quassel.cpp Quassel::registerMetaTypes();
  // FIXME if the function is made static in Quassel source, we can just call it

  // Complex types
  qRegisterMetaType<Message>("Message");
  qRegisterMetaType<BufferInfo>("BufferInfo");
  qRegisterMetaType<NetworkInfo>("NetworkInfo");
  qRegisterMetaType<Network::Server>("Network::Server");
  qRegisterMetaType<Identity>("Identity");
  qRegisterMetaType<Network::ConnectionState>("Network::ConnectionState");

  qRegisterMetaTypeStreamOperators<Message>("Message");
  qRegisterMetaTypeStreamOperators<BufferInfo>("BufferInfo");
  qRegisterMetaTypeStreamOperators<NetworkInfo>("NetworkInfo");
  qRegisterMetaTypeStreamOperators<Network::Server>("Network::Server");
  qRegisterMetaTypeStreamOperators<Identity>("Identity");
  qRegisterMetaTypeStreamOperators<qint8>("Network::ConnectionState");

  qRegisterMetaType<IdentityId>("IdentityId");
  qRegisterMetaType<BufferId>("BufferId");
  qRegisterMetaType<NetworkId>("NetworkId");
  qRegisterMetaType<UserId>("UserId");
  qRegisterMetaType<AccountId>("AccountId");
  qRegisterMetaType<MsgId>("MsgId");

  qRegisterMetaType<QHostAddress>("QHostAddress");

  qRegisterMetaTypeStreamOperators<IdentityId>("IdentityId");
  qRegisterMetaTypeStreamOperators<BufferId>("BufferId");
  qRegisterMetaTypeStreamOperators<NetworkId>("NetworkId");
  qRegisterMetaTypeStreamOperators<UserId>("UserId");
  qRegisterMetaTypeStreamOperators<AccountId>("AccountId");
  qRegisterMetaTypeStreamOperators<MsgId>("MsgId");

  // Versions of Qt prior to 4.7 didn't define QVariant as a meta type
  if(!QMetaType::type("QVariant")) {
    qRegisterMetaType<QVariant>("QVariant");
    qRegisterMetaTypeStreamOperators<QVariant>("QVariant");
  }

  rb_define_singleton_method(rb_define_module("Quassel"), "qt_compress", (VALUE (*)(...))qt_compress, 1);
  rb_define_singleton_method(rb_define_module("Quassel"), "qt_uncompress", (VALUE (*)(...))qt_uncompress, 1);
}

