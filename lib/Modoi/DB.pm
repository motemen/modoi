package Modoi::DB;
use strict;
use warnings;
use base 'Rose::DB';

__PACKAGE__->register_db(
    domain   => 'development',
    type     => 'main',
    driver   => 'sqlite',
    database => './modoi.db', # TODO
    connect_options => {
        unicode => 1,
    },
);

__PACKAGE__->default_domain('development');
__PACKAGE__->default_type('main');

1;
