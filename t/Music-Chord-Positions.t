use strict;
use warnings;

use Test::More tests => 5;

BEGIN { use_ok('Music::Chord::Positions') }
can_ok( 'Music::Chord::Positions', qw/new chord_inv chord_pos/ );

my $mcp = Music::Chord::Positions->new();
isa_ok( $mcp, 'Music::Chord::Positions' );

# 5th should generate 1st and 2nd inversions
my @inversions = $mcp->chord_inv( [ 0, 4, 7 ] );
is_deeply(
  \@inversions,
  [ [ 4, 7, 12 ], [ 7, 12, 16 ] ],
  'check inversions of 5th'
);

# 7th - 1st, 2nd, and 3rd inversions
@inversions = $mcp->chord_inv( [ 0, 4, 7, 11 ] );
is_deeply(
  \@inversions,
  [ [ 4, 7, 11, 12 ], [ 7, 11, 12, 16 ], [ 11, 12, 16, 19 ] ],
  'check inversions of 7th'
);

# 9th - spans octave! (maybe also 15th, 17th to make sure 2x octaves
# does the right thing) - TODO generate lilypond from output to confirm
# things look correct, figure out whether or not will normalize to base
# register if min > $D_I_S.
@inversions = $mcp->chord_inv( [ 0, 4, 7, 11, 14 ] );
#is_deeply(
#  \@inversions,
#  [ [ 4, 7, 11,  12 ], [ 7, 11, 12, 16 ], [ 11, 12, 16, 19 ], [] ],
#  'check inversions of 7th'
#);
#use Data::Dumper; diag Dumper \@inversions;
#
# TODO also 15th, 17th chords to make sure 2x octave spans handled
# correctly.
