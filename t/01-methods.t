#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;

use_ok 'Music::MelodicDevice::Arpeggiation';

subtest defaults => sub {
    my $obj = new_ok 'Music::MelodicDevice::Arpeggiation';# => [ verbose => 1 ];
    ok 1, 'pass';
};

done_testing();
