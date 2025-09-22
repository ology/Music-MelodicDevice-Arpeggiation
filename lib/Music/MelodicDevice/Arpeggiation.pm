package Music::MelodicDevice::Arpeggiation;

# ABSTRACT: Apply arpeggiation patterns to groups of notes

our $VERSION = '0.0200';

use Moo;
use strictures 2;
use Array::Circular ();
use Data::Dumper::Compact qw(ddc);
use namespace::clean;

use constant TICKS => 96;

my $DISPATCH = {
    up     => sub { my ($notes) = @_; return [ 0 .. $#$notes ] },
    down   => sub { my ($notes) = @_; return [ reverse(0 .. $#$notes) ] },
    updown => sub { my ($notes) = @_; return [ 0 .. $#$notes, reverse(0 .. $#$notes) ] },
    random => sub { my ($notes) = @_; return [ map { rand @$notes } @$notes ] },
};

=head1 SYNOPSIS

  use Music::MelodicDevice::Arpeggiation;

  my $arp = Music::MelodicDevice::Arpeggiation->new;

  my $arped = $arp->arp([60,64,67], 1, 'updown', 3);

=head1 DESCRIPTION

C<Music::MelodicDevice::Arpeggiation> applies arpeggiation patterns to
groups of notes.

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

=cut

has type => (
    is      => 'rw',
    isa     => sub { die "$_[0] does not look like a named type" unless $_[0] =~ /^\w+$/ },
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
  $notes = $arp->arp(\@pitches, $duration, $type);
  $notes = $arp->arp(\@pitches, $duration, $type, $repeats);

Return a list of lists of C<d#> MIDI-Perl strings with the pitches indexed by the arpeggiated pattern built from the given C<type>. These MIDI-Perl duration strings are distributed evenly across the given C<duration>.

=cut

sub arp {
    my ($self, $notes, $duration, $type, $repeats) = @_;

    $duration ||= $self->duration;
    $type     ||= $self->type;
    $repeats  ||= $self->repeats;

    my $pattern = ref $type eq 'ARRAY' ? $type : $self->build_pattern($type, $notes);

    my $pat = Array::Circular->new(@$pattern);

    # compute the arp durations
    my $x = $duration * TICKS;
    my $z = sprintf '%0.f', $x / @$notes;
    print "Durations: $x, $z\n" if $self->verbose;
    $z = 'd' . $z;

    my @arp;
    for my $i (1 .. $repeats) {
        for my $j (1 .. @$notes) {
            push @arp, [ $z, $notes->[ $pat->current ] ];
            $pat->next;
        }
    }
    print 'Arp: ', ddc(\@arp) if $self->verbose;

    return \@arp;
}

=head2 build_pattern

  my $pattern = $self->build_pattern($type, $notes);

Return an array refrerence of C<notes> indexes, based on the C<type>, if known.

=cut

sub build_pattern {
    my ($self, $type, $notes) = @_;
    my $dispatch = {
      up     => [ 0 .. $#$notes ],
      down   => [ reverse(0 .. $#$notes) ],
      random => [ map { rand @$notes } @$notes ]
    };
    return $dispatch->{$type};
}

=head2 arp_type

  $all_types = $self->arp_type # get everything
  $coderef = $self->arp_type($type); # get the value
  $self->arp_type($type, $coderef); # set a new type

For no arguments, return the full hash refrerence of all arpeggiation
types. For a single argument, return the code-reference value of that
type, of known. If two arguments are given, add the named C<type> to
the known arpeggiation types with its code-reference value.

Known types and their code-ref values are:

  up     => sub { my ($notes) = @_; return [ 0 .. $#$notes ] },
  down   => sub { my ($notes) = @_; return [ reverse(0 .. $#$notes) ] },
  random => sub { my ($notes) = @_; return [ map { rand @$notes } @$notes ] },

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

1;
__END__

=head1 SEE ALSO

The F<t/01-methods.t> program in this distribution

L<Array::Circular>

L<Data::Dumper::Compact>

L<Moo>

=cut
