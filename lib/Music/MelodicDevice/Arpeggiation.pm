package Music::MelodicDevice::Arpeggiation;

# ABSTRACT: Apply arpeggiation patterns to groups of notes

our $VERSION = '0.0706';

use Moo;
use strictures 2;
use Carp qw(croak);
use Data::Dumper::Compact qw(ddc);
use List::SomeUtils qw(first_index);
use MIDI::Simple ();
use Music::Duration ();
use Music::Scales qw(get_scale_MIDI is_scale);
use namespace::clean;

with('Music::PitchNum');

use constant TICKS => 96;
use constant OCTAVES => 10;

=head1 SYNOPSIS

  use Music::MelodicDevice::Arpeggiation;

  my $arp = Music::MelodicDevice::Arpeggiation->new;

=head1 DESCRIPTION

C<Music::MelodicDevice::Arpeggiation> applies arpeggiation patterns to
groups of notes.

=head1 ATTRIBUTES

=head2 scale_note

Default: C<C>

=cut

has scale_note => (
    is      => 'ro',
    isa     => sub { die "$_[0] is not a valid note" unless $_[0] =~ /^[A-G][#b]?$/ },
    default => sub { 'C' },
);

=head2 scale_name

Default: C<chromatic>

For the chromatic scale, enharmonic notes are listed as sharps.  For a
scale with flats, use a diatonic B<scale_name> with a flat
B<scale_note>.

Please see L<Music::Scales/SCALES> for a list of valid scale names.

=for Pod::Coverage OCTAVES

=cut

has scale_name => (
    is      => 'ro',
    isa     => sub { die "$_[0] is not a valid scale name" unless is_scale($_[0]) },
    default => sub { 'chromatic' },
);

has _scale => (
    is        => 'lazy',
    init_args => undef,
);

sub _build__scale {
    my ($self) = @_;

    my @scale = map { get_scale_MIDI($self->scale_note, $_, $self->scale_name) } -1 .. OCTAVES - 1;
    print 'Scale: ', ddc(\@scale) if $self->verbose;

    return \@scale;
}

=head2 verbose

Default: C<0>

Show the progress of the methods.

=cut

has verbose => (
    is      => 'ro',
    isa     => sub { die "$_[0] is not a valid boolean" unless $_[0] =~ /^[01]$/ },
    default => sub { 0 },
);

=head1 METHODS

=head2 new

  $x = Music::MelodicDevice::Arpeggiation->new(
    scale_note => $scale_note,
    scale_name => $scale_name,
    verbose    => $verbose,
  );

Create a new C<Music::MelodicDevice::Arpeggiation> object.

=for Pod::Coverage TICKS

=cut

=head2 arp

  $notes = $arp->arp($duration, $pitches);

TODO description

=cut

sub turn {
    my ($self, $duration, $pitch, $offset) = @_;

    my $number = 4; # Number of notes in the ornament
    $offset //= 1; # Default one note above

    my $named = $pitch =~ /[A-G]/ ? 1 : 0;

    (my $i, $pitch) = $self->_find_pitch($pitch);
    my $above = $self->_scale->[ $i + $offset ];
    my $below = $self->_scale->[ $i - $offset ];

    if ($named) {
        $pitch = $self->pitchname($pitch);
        $above = $self->pitchname($above);
        $below = $self->pitchname($below);
    }

    # Compute the ornament durations
    my $x = $MIDI::Simple::Length{$duration} * TICKS;
    my $z = sprintf '%0.f', $x / $number;
    print "Durations: $x, $z\n" if $self->verbose;
    $z = 'd' . $z;

    my @turn = ([$z, $above], [$z, $pitch], [$z, $below], [$z, $pitch]);
    print 'Turn: ', ddc(\@turn) if $self->verbose;

    return \@turn;
}

sub _find_pitch {
    my ($self, $pitch, $scale) = @_;

    $scale //= $self->_scale;

    $pitch = $self->pitchnum($pitch)
        if $pitch =~ /[A-G]/;

    my $i = first_index { $_ eq $pitch } @$scale;
    croak "Unknown pitch: $pitch" if $i < 0;

    return $i, $pitch;
}

1;
__END__

=head1 SEE ALSO

The F<t/01-methods.t> and F<eg/*> programs in this distribution

L<Data::Dumper::Compact>

L<List::SomeUtils>

L<MIDI::Simple>

L<Moo>

L<Music::Duration>

L<Music::Scales>

=cut
