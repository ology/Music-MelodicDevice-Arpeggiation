package Music::MelodicDevice::Arpeggiation;

# ABSTRACT: Apply arpeggiation patterns to groups of notes

our $VERSION = '0.0100';

use Moo;
use strictures 2;
use Data::Dumper::Compact qw(ddc);
use namespace::clean;

use constant TICKS => 96;

=head1 SYNOPSIS

  use Music::MelodicDevice::Arpeggiation;

  my $arp = Music::MelodicDevice::Arpeggiation->new;

  my $arped = $arp->arp([qw(C4 E4 G4)], 1, [0,1,2,1,0]);

=head1 DESCRIPTION

C<Music::MelodicDevice::Arpeggiation> applies arpeggiation patterns to
groups of notes.

=head1 ATTRIBUTES

=head2 pattern

Default: C<[0,1,2]>

Arpeggiation note index selection pattern.

=cut

has pattern => (
    is      => 'ro',
    isa     => sub { die "$_[0] is not an array reference" unless ref($_[0]) eq 'ARRAY' },
    default => sub { [0,1,2] },
);

=head2 duration

Default: C<1> (quarter-note)

Duration over which to distribute the arpeggiated pattern of notes.

=cut

has duration => (
    is      => 'ro',
    isa     => sub { die "$_[0] is not a valid duration" unless $_[0] =~ /^\d+\.?(\d+)?$/ },
    default => sub { 1 },
);

=head2 repeats

Default: C<1>

Number of times to repeat the arpeggiated pattern of notes.

=cut

has repeats => (
    is      => 'ro',
    isa     => sub { die "$_[0] is not a positive integer" unless $_[0] =~ /^\d+$/ },
    default => sub { 1 },
);

=head2 verbose

Default: C<0>

Show progress.

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

  $notes = $arp->arp(\@pitches); # use object defaults
  $notes = $arp->arp(\@pitches, $duration);
  $notes = $arp->arp(\@pitches, $duration, \@pattern);
  $notes = $arp->arp(\@pitches, $duration, \@pattern, $repeats);

TODO description

=cut

sub arp {
    my ($self, $notes, $duration, $pattern, $repeats) = @_;

    $duration ||= $self->duration;
    $pattern  ||= $self->pattern;
    $repeats  ||= $self->repeats;

    my $number = @$notes; # Number of notes in the arpeggiation

    # Compute the ornament durations
    my $x = $duration * TICKS;
    my $z = sprintf '%0.f', $x / $number;
    print "Durations: $x, $z\n" if $self->verbose;
    $z = 'd' . $z;

    my @arp;
    for my $i (1 .. $repeats) {
        for my $p (@$pattern) {
            push @arp, [ $z, $notes->[$p] ];
        }
    }
    print 'Arp: ', ddc(\@arp) if $self->verbose;

    return \@arp;
}

1;
__END__

=head1 SEE ALSO

The F<t/01-methods.t> and F<eg/*> programs in this distribution

L<Data::Dumper::Compact>

L<Moo>

=cut
