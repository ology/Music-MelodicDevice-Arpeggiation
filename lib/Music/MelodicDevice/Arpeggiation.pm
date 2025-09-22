package Music::MelodicDevice::Arpeggiation;

# ABSTRACT: Apply arpeggiation patterns to groups of notes

our $VERSION = '0.0104';

use Moo;
use strictures 2;
use Array::Circular ();
use Data::Dumper::Compact qw(ddc);
use namespace::clean;

use constant TICKS => 96;

=head1 SYNOPSIS

  use Music::MelodicDevice::Arpeggiation;

  my $arp = Music::MelodicDevice::Arpeggiation->new;

  my $arped = $arp->arp([60,64,67], 1, [0,1,2,1], 3);

=head1 DESCRIPTION

C<Music::MelodicDevice::Arpeggiation> applies arpeggiation patterns to
groups of notes.

=head1 ATTRIBUTES

=head2 pattern

  $arp->pattern(\@pattern);
  $pattern = $arp->pattern;

Default: C<[0,1,2]>

Arpeggiation note index selection pattern.

=cut

has pattern => (
    is      => 'rw',
    isa     => sub { die "$_[0] is not an array reference" unless ref($_[0]) eq 'ARRAY' },
    default => sub { [0,1,2] },
);

=head2 duration

  $arp->duration($duration);
  $duration = $arp->duration;

Default: C<1> (quarter-note)

Duration over which to distribute the arpeggiated pattern of notes.

=cut

has duration => (
    is      => 'rw',
    isa     => sub { die "$_[0] is not a valid duration" unless $_[0] =~ /^\d+\.?(\d+)?$/ },
    default => sub { 1 },
);

=head2 repeats

  $arp->repeats($repeats);
  $repeats = $arp->repeats;

Default: C<1>

Number of times to repeat the arpeggiated pattern of notes.

=cut

has repeats => (
    is      => 'rw',
    isa     => sub { die "$_[0] is not a positive integer" unless $_[0] =~ /^\d+$/ },
    default => sub { 1 },
);

=head2 verbose

  $arp->verbose($verbose);
  $verbose = $arp->verbose;

Default: C<0>

Show progress.

=cut

has verbose => (
    is      => 'rw',
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
  $notes = $arp->arp(\@pitches, $duration, 0); # <- 0 = random pattern
  $notes = $arp->arp(\@pitches, $duration, \@pattern);
  $notes = $arp->arp(\@pitches, $duration, \@pattern, $repeats);

Return a list of lists of C<d#> MIDI-Perl strings with the pitches indexed by the arpeggiated pattern. These MIDI-Perl duration strings are distributed evenly across the given C<duration>. If the `pattern` is specifically set to an integer greater than zero, random pitch selection is used for that many pitches.

So given a duration of 1 (a quarter-note), a list of 4 notes to arpeggiate, an arpeggiation pattern of C<[0,1,2,3]>, and 1 repeat, this method will return a list of lists with length of the duration divided by the number of pitches. An item of the list is itself a list of 2 elements: the divided duration and the selected pitch given the pattern index.

=cut

sub arp {
    my ($self, $notes, $duration, $pattern, $repeats) = @_;

    $duration ||= $self->duration;
    $repeats  ||= $self->repeats;

    if (defined($pattern) && !ref($pattern) && $pattern =~ /^\d+$/) {
        $pattern = [ map { rand @$notes } 1 .. $pattern ];
    }
    else {
        $pattern ||= $self->pattern;
    }

    # compute the arp durations
    my $x = $duration * TICKS;
    my $z = sprintf '%0.f', $x / @$notes;
    print "Durations: $x, $z\n" if $self->verbose;
    $z = 'd' . $z;

    my $pat = Array::Circular->new(@$pattern);

    my @arp;
    for my $i (1 .. $repeats) {
        for my $j (0 .. $#$notes) {
            push @arp, [ $z, $notes->[ $pat->current ] ];
            $pat->next;
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
