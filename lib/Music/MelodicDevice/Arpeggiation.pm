package Music::MelodicDevice::Arpeggiation;

# ABSTRACT: Apply arpeggiation patterns to groups of notes

our $VERSION = '0.0400';

use Moo;
use strictures 2;
use Array::Circular ();
use Data::Dumper::Compact qw(ddc);
use Music::Note ();
use namespace::clean;

use constant TICKS => 96;

my $DISPATCH = {
    up       => sub { my ($notes) = @_; return [ 0 .. $#$notes ] },
    down     => sub { my ($notes) = @_; return [ reverse(0 .. $#$notes) ] },
    updown   => sub { my ($notes) = @_; return [ 0 .. $#$notes, reverse(0 .. $#$notes - 1) ] },
    random   => sub { my ($notes) = @_; return [ map { rand @$notes } @$notes ] },
    converge => \&converge,
    diverge  => \&diverge,
};

=head1 SYNOPSIS

  use Music::MelodicDevice::Arpeggiation ();

  my $arp = Music::MelodicDevice::Arpeggiation->new;

  # arpeggiate the 'updown' pattern
  my $arped = $arp->arp(['C4','E4','G4'], 1, 'updown');
  # [['d24', 'C4'],['d24', 'E4'],['d24', 'G4'],['d24', 'E4']]
  $arped = $arp->arp([60,64,67], 1, 'updown', 3); # midinums repeated 3 times

  # set a new pattern type
  $arp->arp_type('my_type', sub { my ($notes); return [0,2,1] });

=head1 DESCRIPTION

C<Music::MelodicDevice::Arpeggiation> applies arpeggiation patterns to
groups of notes that can be used with MIDI-Perl.

=head1 ATTRIBUTES

=head2 type

  $arp->type($type);
  $type = $arp->type;

Default: C<up>

Arpeggiation named type.

Known types:

  up
  down
  updown
  random
  converge
  diverge

=cut

has type => (
    is      => 'rw',
    isa     => sub { die "$_[0] is not a known named type" unless exists $DISPATCH->{$_[0]} },
    default => sub { 'up' },
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
    type     => $type,
    duration => $duration,
    repeats  => $repeats,
    verbose  => $verbose,
  );

Create a new C<Music::MelodicDevice::Arpeggiation> object.

=for Pod::Coverage TICKS

=cut

=head2 arp

  $notes = $arp->arp(\@pitches); # use object defaults
  $notes = $arp->arp(\@pitches, $duration);
  $notes = $arp->arp(\@pitches, $duration, $type);
  $notes = $arp->arp(\@pitches, $duration, $type, $repeats);

Return a list of lists of MIDI-Perl notes of the form,
C<['d16','E4']>.

=cut

sub arp {
    my ($self, $notes, $duration, $type, $repeats) = @_;

    $duration ||= $self->duration;
    $type     ||= $self->type;
    $repeats  ||= $self->repeats;

    my $pattern = ref $type eq 'ARRAY' ? $type : $self->_build_pattern($type, $notes);
    print "Pattern: @$pattern\n" if $self->verbose;

    my $pat = Array::Circular->new(@$pattern);

    # compute the arp durations
    my $x = $duration * TICKS;
    my $z = sprintf '%0.f', $x / @$pattern;
    print "Durations: $x, $z\n" if $self->verbose;
    $z = 'd' . $z;

    my @arp;
    for my $i (1 .. $repeats) {
        for my $j (1 .. @$pattern) {
            push @arp, [ $z, $notes->[ $pat->current ] ]
                if $pat->current < @$notes;
            $pat->next;
        }
    }
    print 'Arp: ', ddc(\@arp) if $self->verbose;

    return \@arp;
}

sub _build_pattern {
    my ($self, $type, $notes) = @_;
    return $self->arp_type($type)->($notes);
}

=head2 arp_type

  $all_types = $self->arp_type # get everything
  $coderef = $self->arp_type($type); # get the value
  $self->arp_type($type, $coderef); # set a new type

For no arguments, return the full hash reference of all arpeggiation
types. For a single argument, return the code-reference value of that
type, of known. If two arguments are given, add the named C<type> to
the known arpeggiation types with its code-reference value.

=cut

sub arp_type {
    my ($self, $type, $coderef) = @_;
    if ($type && $coderef) {
        $DISPATCH->{$type} = $coderef;
    }
    elsif ($type) {
        return $DISPATCH->{$type};
    }
    else {
        return $DISPATCH;
    }
}

=head2 converge

Return a list of notes from the outer extremes to the middle.

=cut

sub converge {
    my ($pitches) = @_;

    my @by_pitch = sort { _pitch_value($pitches->[$a]) <=> _pitch_value($pitches->[$b]) } 0 .. $#$pitches;

    my ($lo, $hi) = (0, $#by_pitch);
    my $take_low = 1;
    my @pattern;

    while ($lo <= $hi) {
        if ($lo == $hi) {
            push @pattern, $by_pitch[$lo];
            last;
        }
        push @pattern, $take_low ? $by_pitch[$lo++] : $by_pitch[$hi--];
        $take_low = !$take_low;
    }

    return \@pattern;
}

=head2 diverge

Return a list of notes from the middle to the outer extremes.

=cut

sub diverge {
    my ($pitches) = @_;
    return [ reverse @{ converge($pitches) } ];
}

sub _pitch_value {
    my ($pitch) = @_;
    return $pitch if $pitch =~ /^\d+$/;
    return Music::Note->new($pitch, 'ISO')->format('midinum');
}

1;
__END__

=head1 SEE ALSO

The tests, F<t/01-methods.t> and the F<eg/*> programs in this distribution.

L<Array::Circular>

L<Data::Dumper::Compact>

L<Moo>

=cut
