package Music::Chord::Positions;

use strict;
use warnings;

use Carp qw(croak);
use List::MoreUtils qw(uniq);
use List::Util qw(max min sum);

our $VERSION = '0.01';

my $DEG_IN_SCALE = 12;

sub new {
  my ($class) = @_;
  bless {}, $class;
}

sub chord_inv {
  my ( $self, $pitch_set ) = @_;
  croak "pitch set reference required"
    unless defined $pitch_set and ref $pitch_set eq 'ARRAY';

  my ( @inversions, $max_pitch, $next_register );

  $max_pitch   = max(@$pitch_set);
  $next_register = $max_pitch + $DEG_IN_SCALE - $max_pitch % $DEG_IN_SCALE;

  for my $i ( 0 .. $#$pitch_set - 1 ) {
    # Inversions simply flip lower notes up above the highest pitch in
    # the original pitch set.
    push @inversions,
      [
      @$pitch_set[ $i + 1 .. $#$pitch_set ],
      map { $next_register + $_ } @$pitch_set[ 0 .. $i ]
      ];

    # Normalize to "0th" register if lowest pitch is an octave+ out
    # TODO this is a output/display issue, move to formating routines if
    # write those.
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
# That would be a filter question, not generation or output?
sub chord_pos {
  my ( $self, $pitch_set, %params ) = @_;
  croak "pitch set reference required"
    unless defined $pitch_set and ref $pitch_set eq 'ARRAY';

  # TODO cleanup/reorder
  my ( @ps, $min_pitch_norm, $unique_pitch_count, @potentials, @revoicings,
    $next_register, $voicing_limit );

  $params{'-iinterval-max'} ||= 19;
  $params{'-octaves'}       ||= 3;

  if ( exists $params{'-voices'} ) {
    if ( @$pitch_set > $params{'-voices'} ) {
      die
        "case where pitches in chord exceedes allowed voices not implemented";
    }
  } else {
    $params{'-voices'} = @$pitch_set;
  }

  @ps = sort { $a <=> $b } @$pitch_set;

  $min_pitch_norm     = $ps[0] % $DEG_IN_SCALE;
  $next_register        = $ps[-1] + ( $DEG_IN_SCALE - $ps[-1] % $DEG_IN_SCALE );
  $unique_pitch_count = sum( uniq( map { $_ % $DEG_IN_SCALE } @ps ) );
  $voicing_limit      = $next_register * ( $params{'-octaves'} - 1 );

  if ( $params{'-voices'} > @ps ) {
    my $doubled_count = $params{'-voices'} - @ps;
    die "multiple extra voices not implemented" if $doubled_count > 1;

    # Double lowest pitch in octave above higest pitch C E G -> C E G C
    push @ps, $next_register + $ps[0];
  }

  @potentials = @ps;
  for my $i ( 1 .. $params{'-octaves'} ) {
    for my $n (@ps) {
      push @potentials, $n + $i * $DEG_IN_SCALE;
    }
  }
  @potentials = uniq sort { $a <=> $b } @potentials;

  while (1) {
    # TODO write loop/state instead of nested for (static voices) or recursive
  }

  return @revoicings;
}

1;
__END__

=head1 NAME

Music::Chord::Positions - generate various chord inversions and voicings

=head1 SYNOPSIS

  use Music::Chord::Positions;
  my $mcp = Music::Chord::Positions->new();

  my @inverses = $mcp->chord_inv([0,4,7]);
  my @voicings = $mcp->chord_pos([0,4,7]);

=head1 DESCRIPTION

Utility methods for generating inversions or chord voicing variations of
a given pitch set. A pitch set is an array reference consisting of
semitone intervals that could constitute some sort of chord.

  [0, 4, 7]      # Major      C  E  G
  [0, 3, 7]      # minor      C  D# G
  [0, 4, 7, 11]  # Major 7th  C  E  G  B

The pitch set may be specified manually, or the B<chord_num> method of
L<Music::Chord::Note> used to derive a pitch set from a named chord. So
the following should result in identical lists of inversions of C minor.

  my @ps = (0,3,7);
  $mcp->chord_inv(\@ps);

  use Music::Chord::Note;
  $mcp->chord_inv([ Music::Chord::Note->new->chord_num('Cm') ]);

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
