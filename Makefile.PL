use inc::Module::Install;
name 'Hoya';
all_from 'lib/Hoya.pm';

requires 'URI::Escape';
requires 'YAML::Syck';
requires 'JSON::Syck';
requires 'UUID::Tiny';
requires 'Data::Recursive::Encode';
requires 'Hash::Merge';
requires 'Text::MicroTemplate::Extended';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
auto_set_repository;
auto_include;
WriteAll;
