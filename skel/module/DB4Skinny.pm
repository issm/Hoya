package MyProject::DB::MyDB;
use DBIx::Skinny setup => +{
    dsn      => 'dbi:mysql:{dbname}',
    username => '{username}',
    password => '{password}',
};
1;


package MyProject::DB::MyDB::Schema;
use base qw/DBIx::Skinny::Schema::Loader/;
use DBIx::Skinny::Schema;
use utf8;

# utf-8 columns
#install_utf8_columns qw/name
#                       /;

#install_table table => schema {
#};

#install_inflate_rule '...' => callback {
#    inflate {
#        my $v = shift;
#        return $v;
#    };
#    deflate {
#        my $v = shift;
#        return $v;
#    };
#};

__PACKAGE__->load_schema;


1;
