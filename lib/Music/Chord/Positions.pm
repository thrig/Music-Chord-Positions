# TODO
# * chord_pos
#   - support arbitrary? voice counts (would need doubling rules?) Extra
#     voices would likely run into either doubling or maximum pitch
#     limits, so might need good-enough effort (or lots of doublings)?
#   - or lower than @ps voice count, which might require new logic or
#     priority on the pitches?
#   - inversion through "root_any" and then select only root 3rd or
#     whatever afterwards?
#   - nix octave_count and pitch_max in favor of just specified
#     semitones up? - makes sense, as interval_adj_max is a semitone
#     thing.
#   - doublings could use more rules beyond "no" or "anything goes",
#     perhaps optional list of "here's pitches that can be doubled" so
#     can 2x the root or the 5th or whatever on demand.
#   - logic tricky, could it be simplified with a Combinations module or
#     by using ordering results from a glob() expansion?
#   - callbacks so caller can better control the results?
#
# * progressions
#   - support this, instead of using mcp-prog script?

package Music::Chord::Positions;

use strict;
use warnings;

use Carp qw(croak);
use Exporter ();
use List::MoreUtils qw(all uniq);
use List::Util qw(max min);

our $VERSION = '0.07';

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

  if ( exists $params{'voice_count'} ) {
    die "voice_count not supported for inversions";
  }

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

  $params{'interval_adj_max'} =
    ( exists $params{'interval_adj_max'}
      and defined $params{'interval_adj_max'} )
    ? $params{'interval_adj_max'}
    : 19;

  if ( exists $params{'octave_count'} ) {
    $params{'octave_count'} = 2 if $params{'octave_count'} < 2;
  } else {
    $params{'octave_count'} = 2;
  }

  if ( exists $params{'pitch_max'} and $params{'pitch_max'} < 1 ) {
    $params{'pitch_max'} =
      ( $params{'octave_count'} + 1 ) * $DEG_IN_SCALE + $params{'pitch_max'};
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
      my $p = $n + $i * $DEG_IN_SCALE;
      push @potentials, $p
        unless exists $params{'pitch_max'} and $p > $params{'pitch_max'};
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

      my ( @intervals, %intv_by_idx );
      for my $j ( 1 .. $#chord ) {
        push @intervals, $chord[$j] - $chord[ $j - 1 ];
        next TOPV if $intervals[-1] > $params{'interval_adj_max'};

        $intv_by_idx{ $j - 1 } = $intervals[-1] if @chord > 2;
      }
      # TODO these routines have not been tested against chords with 5+
      # voices, so may allow pitch sets that violate the spirit of the
      # following (3rds in the middle of otherwise open voicings would
      # be what I would expect to see pass in 5+ voice chords).
      if (  @chord > 2
        and exists $params{'no_partial_closed'}
        and $params{'no_partial_closed'} ) {
        # Exclude 3rds near fundamental where next voice 5th+ out
        if ( $intervals[0] < 5 and $intervals[1] > 6 ) {
          next TOPV;
        }
        # Exclude 3rds at top where next lower voice 5th+ out
        if ( $intervals[-1] < 5 and $intervals[-2] > 6 ) {
          next TOPV;
        }

        # Exclude cases where highest voice has wandered off by a larger
        # interval than seen below.
        my @ordered_intv =
          sort { $intv_by_idx{$b} <=> $intv_by_idx{$a} } keys %intv_by_idx;
        if ( $ordered_intv[0] > $ordered_intv[-1]
          and all { $intv_by_idx{ $ordered_intv[0] } > 1 + $intv_by_idx{$_} }
          @ordered_intv[ 1 .. $#ordered_intv ] ) {
          next TOPV;
        }
      }

      # Nix any identical chord voicings (c e g == c' e' g')
      unless ( exists $params{'allow_transpositions'}
        and $params{'allow_transpositions'} ) {
        next TOPV if $seen_intervals{"@intervals"}++;
      }

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
  my @voicings = chord_pos([0,4,7], voice_count => 4);

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
specific functions, or use the C<:all> import tag.

=over 4

=item B<chord_inv>( I<pitch set reference>, I<list of optional paramters> ... )

Generates inversions of the pitch set, returns a list of pitch sets
(list of array references). The order of the results will be 1st
inversion, 2nd inversion, etc.

No transposition is performed, so inversions of 9ths or larger may
result in a chord in a register above the original. If this is a
problem, decrement the semitones in the pitch set by 12 or whatever.

Parameter accepted (just one):

=over 4

=item B<pitch_norm> => I<0>

If set and true, transposes inversions down if lowest pitch of said
inversion is greater than the degrees in the scale.

=back

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

The default settings for C<chord_pos()> generate more voicings than may
be permitted by music theory; a set more in line with what Schoenberg
outlines in his chord positions chapter would require something like:

  my @chords = chord_pos(
    [qw/0 4 7/],
    allow_transpositions =>  1, # as SATB can transpose up
    no_partial_closed    =>  1, # exclude half open/closed positions
    pitch_max            => -1, # avoids 36 (c''') in Soprano
  );

Though Schoenberg later on uses voicings the above would exclude when
dealing with sevenths, so restrictions might be best done after
reviewing the full list of resulting chords for the desired qualities,
not starting from a limited set of assumed desired outcomes.

The B<chord_pos> method can be influenced by the following parameters
(default values are shown). Beware that removing restrictions may result
in many, many, many different voicings for larger pitch sets.

=over 4

=item B<allow_transpositions> => I<0>

If set and true, allows transpositions of identical pitch sets into
higher registers. That is, permit both 0 4 7 and 12 16 19.

=item B<interval_adj_max> => I<19>

Largest interval allowed between two adjacent voices, in semitones.

=item B<no_limit_doublings> => I<0>

If set and true, allows doublings on all pitches, not just the default
of the root pitch.

=item B<no_limit_uniq> => I<0>

If set and true, disables the unique pitch check. That is, voicings will
be allowed with fewer pitches than in the original pitch set.

=item B<no_partial_closed> => I<0>

If set and true, disallows vocings somewhere between close position
and open position. See C<t/Schoenberg.t> and the source for what is
being done.

=item B<octave_count> => I<2>

How far above the register of the chord to generate voicings in. If set
to a large value, the B<interval_adj_max> value may also need to be
increased. The B<pitch_max> parameter can be used to fine-tune the
maximum pitch generated inside the set generated by this option.

=item B<pitch_max> => I<inf>

Maximum pitch to allow, in semitones. For fine-grained control below the
span generated by the B<octave_count> parameter. If positive, counts in
semitones up from the lowest pitch to determine the maximum. If zero or
negative, counts down from the B<octave_count> + 1 interval instead.

=item B<root_any> => I<0>

If set and true, allows the root pitch of the voicing to be any member
of the original pitch set, not just the lowest of that set. Pointless if
B<root_lock> set.

=item B<root_lock> => I<0>

Prevent the root pitch from changing in the generated positions. Defeats
B<root_any> option.

=item B<voice_count> => I<depends on pitch set passed>

Use this to customize the number of voices in the different chord
voicings. At present, only one extra voice above the number of voices
in the pitch set is implemented. Mostly to support SATB for three-
pitch chords, in which case the root pitch will be doubled:

  chord_pos([0,4,7], voice_count => 4);

=back

The chord voicings allowed by the default options may still not suit
certain musical styles; for example, in SATB chorales, the bass alone is
allowed to drift far from the other voices, but not both the bass and
tenor from the upper voices. Voicings are not restricted by the limits
of the human voice or for other instruments; checks of this nature would
need to be done by the calling code on the results.

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

B<Theory of Harmony> by Arnold Schoenberg (ISBN 978-0-520-26608-7).
Whose simple chord voicing exercise prompted this not as simple
diversion in coding.

=head1 AUTHOR

Jeremy Mates E<lt>jmates@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011-2012 Jeremy Mates

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself, either Perl version 5.14 or, at
your option, any later version of Perl 5 you may have available.

=cut
