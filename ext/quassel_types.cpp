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
VALUE unserialize(VALUE self, VALUE string);


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

  QuasselTypes = rb_define_module("QuasselTypes");
  rb_define_singleton_method(QuasselTypes, "unserialize", (VALUE (*)(...))unserialize, 1);
}

VALUE unserialize(VALUE self, VALUE string)
{
  Check_Type(string, T_STRING);

  QByteArray byte_array(RSTRING_PTR(string), RSTRING_LEN(string));
  QDataStream data_stream(byte_array);
  QVariant variant;
  data_stream >> variant;

  // FIXME return a Ruby object for the variant instead of its qDebug
  QString output;
  QDebug debug(&output);

  debug << variant;

  VALUE result = rb_str_new2(output.toUtf8().data());
  rb_enc_associate_index(string, rb_enc_find_index("UTF-8"));
  return result;
}

