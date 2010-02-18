use inc::Module::Install;
name 'Hoya';
all_from 'lib/Hoya.pm';

requires 'URI::Escape';
requires 'YAML::Syck';
requires 'JSON::Syck';
requires 'UUID::Tiny';
requires 'Data::Recursive::Encode';
requires 'Hash::Merge';
requires 'Hash::MultiValue';
requires 'Text::MicroTemplate::Extended';
requires 'Digest::SHA1';
requires 'Try::Tiny';
requires 'Log::Dispatch';
requires 'Data::Dumper';
requires 'Data::Dump';

#requires 'Log::Dispatch::DesktopNotification'; # optional

#requires 'MIME::Lite';
#requires 'MIME::Types';
#requires 'Image::Magick';
#requires 'Image:Size';
#requires 'PDF::API2';
#requires 'PDF::API2::Lite';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
auto_set_repository;
auto_include;
WriteAll;
