#include <ruby.h>
#include <ruby/encoding.h>
#include <QByteArray>
#include <QDataStream>
#include <QString>
#include <QDebug>

VALUE QuasselTypes;
extern "C" {
  void Init_QuasselTypes();
}
VALUE unserialize(VALUE self, VALUE string);


void Init_QuasselTypes() {
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

