package Music::Chord::Positions;

use strict;
use warnings;

use Carp qw(croak);
use Exporter ();
use List::MoreUtils qw(uniq);
use List::Util qw(max min);

our $VERSION = '0.04';

our ( @ISA, @EXPORT_OK, %EXPORT_TAGS );
@ISA = qw(Exporter);

@EXPORT_OK = qw(&chord_inv &chord_pos &chords2voices &scale_deg);
%EXPORT_TAGS = ( all => [qw(chord_inv chord_pos chords2voices scale_deg)] );

my $DEG_IN_SCALE = 12;

########################################################################
#
# SUBROUTINES

sub chord_inv {
  my ( $pitch_set, %params ) = @_;
  croak "pitch set reference required"
    unless defined $pitch_set and ref $pitch_set eq 'ARRAY';

  my ( @inversions, $max_pitch, $next_register );

  $max_pitch     = max(@$pitch_set);
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
    if ( exists $params{'pitch_norm'} and $params{'pitch_norm'} ) {
      my $min_pitch = min( @{ $inversions[-1] } );
      if ( $min_pitch >= $DEG_IN_SCALE ) {
        my $offset = $min_pitch - $min_pitch % $DEG_IN_SCALE;
        $_ -= $offset for @{ $inversions[-1] };
      }
    }
  }

  return @inversions;
}

sub chord_pos {
  my ( $pitch_set, %params ) = @_;
  croak "pitch set reference required"
    unless defined $pitch_set and ref $pitch_set eq 'ARRAY';

  my (
    @ps,             @potentials,    @revoicings,
    @voice_iters,    @voice_max,     %seen_intervals,
    $min_pitch_norm, $next_register, $unique_pitch_count,
  );

  $params{'interval_adj_max'} ||= 19;

  if ( exists $params{'octave_count'} ) {
    $params{'octave_count'} = 2 if $params{'octave_count'} < 2;
  } else {
    $params{'octave_count'} = 2;
  }

  if ( exists $params{'voice_count'} ) {
    if ( @$pitch_set > $params{'voice_count'} ) {
      die
        "case where pitches in chord exceeds allowed voices not implemented";
    }
  } else {
    $params{'voice_count'} = @$pitch_set;
  }

  @ps = sort { $a <=> $b } @$pitch_set;

  $min_pitch_norm     = $ps[0] % $DEG_IN_SCALE;
  $next_register      = $ps[-1] + ( $DEG_IN_SCALE - $ps[-1] % $DEG_IN_SCALE );
  $unique_pitch_count = ( uniq( map { $_ % $DEG_IN_SCALE } @ps ) );

  if ( $params{'voice_count'} > @ps ) {
    my $doubled_count = $params{'voice_count'} - @ps;
    die "multiple extra voices not implemented" if $doubled_count > 1;

    # Double lowest pitch in octave above highest pitch C E G -> C E G C
    push @ps, $next_register + $ps[0];
  }

  @potentials = @ps;
  for my $i ( 1 .. $params{'octave_count'} ) {
    for my $n (@ps) {
      push @potentials, $n + $i * $DEG_IN_SCALE;
    }
  }
  @potentials = uniq sort { $a <=> $b } @potentials;

  for my $i ( 0 .. $params{'voice_count'} - 1 ) {
    $voice_iters[$i] = $i;
    $voice_max[$i]   = $#potentials - $params{'voice_count'} + $i + 1;
  }
  if ( exists $params{'root_lock'} and $params{'root_lock'} ) {
    $voice_max[0] = $voice_iters[0];
  }

  while ( $voice_iters[0] <= $voice_max[0] ) {
  TOPV: while ( $voice_iters[-1] <= $voice_max[-1] ) {
      my @chord = @potentials[@voice_iters];
      $voice_iters[-1]++;

      my %harmeq;
      for my $p (@chord) {
        $harmeq{ $p % $DEG_IN_SCALE }++;
      }

      unless ( exists $params{'no_limit_uniq'} and $params{'no_limit_uniq'} )
      {
        next if keys %harmeq < $unique_pitch_count;
      }

      unless ( exists $params{'no_limit_doublings'}
        and $params{'no_limit_doublings'} ) {
        for my $k ( grep { $_ != $min_pitch_norm } keys %harmeq ) {
          next TOPV if $harmeq{$k} > 1;
        }
      }

      # Nix any identical chord voicings (c e g == c' e' g')
      my @intervals;
      for my $j ( 1 .. $#chord ) {
        push @intervals, $chord[$j] - $chord[ $j - 1 ];
        next TOPV if $intervals[-1] > $params{'interval_adj_max'};
      }
      next TOPV if $seen_intervals{"@intervals"}++;

      push @revoicings, \@chord;
    }

    # Increment any lower voices if top voice(s) maxed out
    for my $i ( reverse 1 .. $#voice_iters ) {
      if ( $voice_iters[$i] > $voice_max[$i] ) {
        $voice_iters[ $i - 1 ]++;
      }
    }

    unless ( exists $params{'root_any'} and $params{'root_any'} ) {
      while (
        $potentials[ $voice_iters[0] ] % $DEG_IN_SCALE != $min_pitch_norm ) {
        $voice_iters[0]++;
        last if $voice_iters[0] > $voice_max[0];
      }
    }

    # Reset higher voices to close positions above lower voices
    for my $i ( 1 .. $#voice_iters ) {
      if ( $voice_iters[$i] > $voice_max[$i] ) {
        $voice_iters[$i] = $voice_iters[ $i - 1 ] + 1;
      }
    }
  }

  return @revoicings;
}

# Change a pitch set collection (vertical) into voices (horizontal)
sub chords2voices {
  my (@pitch_sets) = @_;
  croak "not a list of pitch sets" unless ref $pitch_sets[0] eq 'ARRAY';

  # Nothing to swap, change nothing
  return @pitch_sets if @pitch_sets < 2;

  my @voices;

  for my $vi ( 0 .. $#{ $pitch_sets[0] } ) {
    for my $j ( 0 .. $#pitch_sets ) {
      push @{ $voices[$vi] }, $pitch_sets[$j][$vi];
    }
  }

  return reverse @voices;
}

sub scale_deg { $DEG_IN_SCALE }

1;
__END__

=head1 NAME

Music::Chord::Positions - generate various chord inversions and voicings

=head1 SYNOPSIS

  use Music::Chord::Positions qw/:all/;

  my @inverses = chord_inv([0,4,7]);
  my @voicings = chord_pos([0,4,7]);

  my @voices = chords2voices(@inverses);

Interface may be subject to change without notice!

=head1 DESCRIPTION

Utility methods for generating inversions or chord voicing variations of
a given pitch set. A pitch set is an array reference consisting of
semitone intervals, for example:

  [0, 4, 7]      # Major      C  E  G
  [0, 3, 7]      # minor      C  D# G
  [0, 4, 7, 11]  # Major 7th  C  E  G  B

Or whatever. The pitch set may be specified manually, or the
B<chord_num> method of L<Music::Chord::Note> used to derive a pitch set
from a named chord.

  use Music::Chord::Positions qw/:all/;
  use Music::Chord::Note;

  # These both result in the same output from chord_inv()
  my @i1 = chord_inv([ 0,3,7                                   ]);
  my @i2 = chord_inv([ Music::Chord::Note->new->chord_num('m') ]);

Using the resulting pitch sets and so forth left as exercise to user;
converting the semitones to L<MIDI::Simple> or voices to lilypond
compatible output should not be too difficult (see the C<eg> directory
of this module's distribution for sample scripts).

=head1 SUBROUTINES

Nothing exported by default. Use the fully qualified path, or import
stuff. If OO desired, code something up?

=over 4

=item B<chord_inv>( I<pitch set reference> )

Generates inversions of the pitch set, returns a list of pitch sets
(list of array references). The order of the results will be 1st
inversion, 2nd inversion, etc.

No transposition is performed, so inversions of 9ths or larger may
result in a chord in a register above the original. If this is a
problem, decrement the semitones in the pitch set by 12 or whatever.

=item B<chord_pos>( I<pitch set reference>, I<list of optional parameters> ... )

Generate different voicings of a different chord, by default in
registers two above the base. Returns list of pitch sets (list of array
references) in who knows what order.

Only voicings where the root remains in the root will be considered;
chords that do not represent all pitches in the pitch set or chords that
double non-root pitches will be excluded. Chords with intervals greater
than 19 semitones (octave+fifth) between adjacent pitches will also be
excluded, as will transpositions of the same voicing into higher
registers.

The B<chord_pos> method can be influenced by the following parameters
(default values are shown). Beware that removing restrictions may result
in many, many, many different voicings for larger pitch sets.

=over 4

=item B<interval_adj_max> I<19>

Largest interval allowed between two adjacent voices, in semitones.

=item B<no_limit_doublings> I<0>

If set and true, allows doublings on all pitches, not just the default
of the root pitch.

=item B<no_limit_uniq> I<0>

If set and true, disables the unique pitch check. That is, voicings will
be allowed with fewer pitches than in the original pitch set.

=item B<octave_count> I<2>

How far above the register of the chord to generate voicings in. If set
to a large value, the B<interval_adj_max> value may also need to be
increased.

=item B<root_any> I<0>

If set and true, allows the root pitch of the voicing to be any member
of the original pitch set, not just the lowest of that set. Pointless if
B<root_lock> set.

=item B<root_lock> I<0>

Prevent the root pitch from changing in the generated positions. Defeats
B<root_any> option.

=item B<voice_count> I<depends on pitch set passed>

Use this to customize the number of voices in the different chord
voicings. At present, only one extra voice above the number of voices
in the pitch set is implemented. Mostly to support SATB for three-
pitch chords, in which case the root pitch will be doubled:

  chord_pos([0,4,7], voice_count => 4);

=back

The chord voicings allowed by the default options may still not suit
certain musical styles; for example, in SATB chorales, the bass alone is
allowed to drift far from the other voices, but not both the bass and
tenor from the upper voices.

=item B<chords2voices>( I<pitch set list> )

Accepts a pitch set list (such as returned by B<chord_pos>), transposes
vertical chords into horizontal voices. Returns list of voices, highest
to lowest. Returns the original pitch set list if nothing to transpose.

=item B<scale_deg>( )

Returns number of degrees in the scale. Should always be 12, unless
someone sneaks in support for alternate scale systems in behind my back.

=back

=head1 SEE ALSO

L<Music::Chord::Note>

B<Theory of Harmony> by Arnold Schoenberg. Whose simple chord voicing
exercise prompted this not as simple diversion in coding.

=head1 AUTHOR

Jeremy Mates E<lt>jmates@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 Jeremy Mates

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself, either Perl version 5.14 or, at
your option, any later version of Perl 5 you may have available.

=cut
