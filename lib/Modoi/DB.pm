package Modoi::DB;
use strict;
use warnings;
use base qw(Rose::DB);
use FindBin;

__PACKAGE__->use_private_registry;

__PACKAGE__->register_db(
    driver   => 'sqlite',
    database => "$FindBin::Bin/modoi.db",
    connect_options => {
        unicode => 1,
    },
);

1;
