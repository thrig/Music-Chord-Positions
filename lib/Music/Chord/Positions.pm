package Music::Chord::Positions;

use strict;
use warnings;

use Carp qw(croak);
use List::Util qw(min max);

our $VERSION = '0.01';

my $DEG_IN_SCALE = 12;

sub new {
  my ($class) = @_;
  bless {}, $class;
}

sub chord_inv {
  my ( $self, $pitch_set, %params ) = @_;
  croak "chord_inv requires a pitch set"
    unless defined $pitch_set and ref $pitch_set eq 'ARRAY';

  my $max_pitch   = max(@$pitch_set);
  my $next_octave = $max_pitch + $DEG_IN_SCALE - $max_pitch % $DEG_IN_SCALE;

  my @inversions;
  for my $i ( 0 .. $#$pitch_set - 1 ) {
    # Inversions simply flip lower notes up above the highest pitch in
    # the original pitch set.
    push @inversions,
      [
      @$pitch_set[ $i + 1 .. $#$pitch_set ],
      map { $next_octave + $_ } @$pitch_set[ 0 .. $i ]
      ];

    # Normalize to "0th" register if lowest pitch is an octave+ out    TODO
    # not sure if I want this change, as it is display/output related.       :/
    #   my $min_pitch = min( @{ $inversions[-1] } );
    #   if ( $min_pitch >= $DEG_IN_SCALE ) {
    #     my $offset = $min_pitch - $min_pitch % $DEG_IN_SCALE;
    #     $_ -= $offset for @{ $inversions[-1] };
    #   }
  }

  return @inversions;
}

# TODO options for voices (could be > = < than pitch set), whether to
# allow doubling and if so on what degrees (root, 5th, 3rd, ..., all)
# doubling is allowed. Ohh, also top limit for voicings, as computers
# could numerate voices out to crazy spans (3 would be a good limit for
# 5ths, as Theory of Harmony only extends open position to 2+5th, might
# need more for 13th chords). Also means to limit by 'closed' or 'open'
# position definition from ToH, etc.
#
# And whether chords suit SATB vocal ranges or not (or how well?) hmm.
sub chord_pos {
  my ( $self, $pitch_set, %params ) = @_;

  croak "chord_pos requires a pitch set"
    unless defined $pitch_set and ref $pitch_set eq 'ARRAY';

  # DBG until I figure out how to handle 3 or 5 or what (unset would
  # imply to take the # of "voices" from the chord?)
  $params{'-voices'} = 4;
  $params{'-factor'} = 3;    # TODO need better name

  if ( @$pitch_set > $params{'-voices'} ) {
    # as would need to figure out what are the permitted doublings, etc.
    croak
      "case where pitches in chord exceedes allowed voices not implemented\n";
  }

  my $max_interval = max @$pitch_set;

  # How high above fundamental to allow
  my $voicing_limit =
    ( $max_interval + $DEG_IN_SCALE - $max_interval % $DEG_IN_SCALE ) *
    $params{'-factor'};

  if ( @$pitch_set < $params{'-voices'} ) {
    # TODO if delta 1 easy just add octave, what to do if 5 voices for a 3
    # pitch chord?
  }

  # Calculate different positions (revoicing, same fundamental tone).
  my @revoicings;

  return @revoicings;
}

1;
__END__

=head1 NAME

Music::Chord::Positions - generates various chord voicings

=head1 SYNOPSIS

  use Music::Chord::Positions;
  my $mcp = Music::Chord::Positions->new();

  TODO

=head1 DESCRIPTION

Given a set of semitone intervals (as an array ref), generates alternate
voicings for those pitches in the modern Western system. The voicings
(TODO will) include closed or open position variations (up to an upper
limit), and inversions. The pitch set may be specified manually, or the
B<chord_num> method of L<Music::Chord::Note> used to derive a pitch set
from a named chord.

=head1 SEE ALSO

L<Music::Chord::Note>

B<Theory of Harmony> by Arnold Schoenberg

=head1 AUTHOR

Jeremy Mates E<lt>jmates@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 Jeremy Mates

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself, either Perl version 5.14 or, at
your option, any later version of Perl 5 you may have available.

=cut
