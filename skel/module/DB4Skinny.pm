use strict;
use warnings;


package MyProject::DB::MyDB;
use DBIx::Skinny;
1;


package MyProject::DB::MyDB::Schema;
use DBIx::Skinny::Schema;
use utf8;

# DBIx::Skinny::Schema::Loader->make_schema_at() が便利

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



1;
