use strict;
use warnings;

use Test::More tests => 8;

BEGIN { use_ok('Music::Chord::Positions') }
can_ok( 'Music::Chord::Positions',
  qw/chord_inv chord_pos chords2voices scale_deg/ );

########################################################################
#
# chord_inv tests

# 5th should generate 1st and 2nd inversions
my @inversions = Music::Chord::Positions::chord_inv( [ 0, 4, 7 ] );
is_deeply(
  \@inversions,
  [ [ 4, 7, 12 ], [ 7, 12, 16 ] ],
  'check inversions of 5th'
);

# 7th - 1st, 2nd, and 3rd inversions
@inversions = Music::Chord::Positions::chord_inv( [ 0, 4, 7, 11 ] );
is_deeply(
  \@inversions,
  [ [ 4, 7, 11, 12 ], [ 7, 11, 12, 16 ], [ 11, 12, 16, 19 ] ],
  'check inversions of 7th'
);

# pitch_norm
@inversions =
  Music::Chord::Positions::chord_inv( [ 0, 4, 7, 10, 13 ], pitch_norm => 1 );
is_deeply(
  \@inversions,
  [ [ 4,  7,  10, 13, 24 ],
    [ 7,  10, 13, 24, 28 ],
    [ 10, 13, 24, 28, 31 ],
    [ 1,  12, 16, 19, 22 ],
  ],
  'inversion with pitch_norm'
);

########################################################################
#
# chord_pos tests

# TODO not sure what normal is for voicings and default parameters :/
# use mcp2ly and inspect scores by hand, deal with any oddities or need
# for new parameters as necessary.

########################################################################
#
# chords2voices tests

is_deeply(
  [ Music::Chord::Positions::chords2voices( [qw/1 2 3/], [qw/1 2 3/] ) ],
  [ [qw/3 3/], [qw/2 2/], [qw/1 1/] ],
  'simple chord to voice switch'
);
is_deeply(
  [ Music::Chord::Positions::chords2voices( [qw/1 2 3/] ) ],
  [ [qw/1 2 3/] ],
  'nothing for chords2voices to do'
);

########################################################################
#
# scale_deg test

is( Music::Chord::Positions::scale_deg(), 12, 'degress in scale' );
