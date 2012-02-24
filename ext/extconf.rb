require 'mkmf'

$CPPFLAGS += ' -I/usr/include/QtCore'
$CPPFLAGS += ' -I/usr/include/QtNetwork'

have_library 'QtCore', nil
have_library 'QtNetwork', nil

Dir.glob('*.h').each do |header|
  system "moc #{header} -o moc_#{File.basename header, '.h'}.cpp"
end

create_makefile("QuasselTypes")
