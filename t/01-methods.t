#perl
use Test::More;

use_ok 'Music::MelodicDevice::Arpeggiation';

subtest defaults => sub {
    my $mda = new_ok 'Music::MelodicDevice::Arpeggiation';# => [ verbose => 1 ];
    is $mda->duration, 1, 'duratiion';
    is_deeply $mda->pattern, [0,1,2], 'pattern';
    is $mda->repeats, 1, 'repeats';
};

done_testing();
