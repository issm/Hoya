use inc::Module::Install;


name 'Hoya';
all_from 'lib/Hoya.pm';


requires 'UNIVERSAL::require';            #
requires 'Plack';                         #
requires 'Plack::Middleware::Session';    #
requires 'URI::Escape';                   # Hoya::Mapper::URL, Hoya::View::MT
requires 'YAML::Syck';                    # Hoya::Config::Core?, Hoya::DSH::DBI, Hoya::Form, Hoya::Mapper::URL, Hoya::Mapper::UserAgent
requires 'JSON::Syck';                    #
requires 'UUID::Tiny';                    # Hoya::Util
requires 'Data::Recursive::Encode';       # Hoya::Util
requires 'Hash::Merge';                   # Hoya::Util, Hoya::Mapper::URL
requires 'Hash::MultiValue';              # Hoya::Util, Hoya::Action, Hoya::Action::* (dynamically), Hoya::Model::* (dynamically), Hoya::Form::Validator, Hoya::Mapper::URL, 
requires 'XML::TreePP';                   # Hoya::View
requires 'Text::MicroTemplate::Extended'; # Hoya::View::MT
requires 'Cache::FileCache';              # Hoya::DSH;
requires 'DBI';                           # Hoya::DSH::DBIx::Skinny, Hoya::DSH::DBI
requires 'DBIx::Skinny';                  # Hoya::DSH::DBIx::Skinny
requires 'Digest::SHA1';                  # Hoya::DSH::DBI
requires 'Try::Tiny';                     # almost all in Hoya modules
requires 'Log::Dispatch';                 #
requires 'Data::Dumper';                  # Hoya::Util
requires 'Data::Dump';                    # Hoya::Util
requires 'Params::Validate';              # Hoya::Model::* (dynamically), Hoya::Action, Hoya::Form::Validator, 
requires 'List::MoreUtils';               # Hoya::Form::Validator
requires 'Data::Page';                    # Hoya::Action, Hoya::Model::* (dynamically)

if ($ENV{HOYA_USE_X}) {
    #requires 'Log::Dispatch::DesktopNotification';  # optional
    requires 'MIME::Lite';                          # Hoya::X::Mail
    requires 'MIME::Types';                         # Hoya::X::Mail?
    requires 'Image::Magick';
    requires 'Image::Size';
    requires 'PDF::API2';                           # Hoya::X::PDF
    requires 'PDF::API2::Lite';                     # Hoya::X::PDF
    requires 'LWP::UserAgent';                      # Hoya::X::Business::Payment::Epsilon
    requires 'Crypt::SSLeay';                       # Hoya::X::Business::Payment::Epsilon
    requires 'XML::Simple';                         # Hoya::X::Business::Payment::Epsilon
    requires 'HTTP::Request::Common';               # Hoya::X::Business::Payment::Epsilon
}

test_requires 'Test::More';               # *.t
test_requires 'Test::These';              # *.t
test_requires 'Data::Random';             # Hoya::Re
test_requires 'Data::Random::WordList';   # Hoya::Re
test_requires 'Clone';                    # Hoya::Action, Hoya::X::Params::Validate::Spec
test_requires 'Text::MediawikiFormat';    # Hoya::X::Text::MediawikiFormat


tests 't/*.t t/*/*.t t/*/*/*.t';
#author_tests 'xt';


auto_install;
auto_set_repository;
auto_include;
WriteAll;
