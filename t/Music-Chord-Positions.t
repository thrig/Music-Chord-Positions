use strict;
use warnings;

use Test::More tests => 5;

BEGIN { use_ok('Music::Chord::Positions') }
can_ok( 'Music::Chord::Positions', qw/new chord_inv chord_pos/ );

my $mcp = Music::Chord::Positions->new();
isa_ok( $mcp, 'Music::Chord::Positions' );

########################################################################
#
# chord_inv tests

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
# TODO also 8th or [0,4,7,12] which gets into how doubling is handled!

########################################################################
#
# chord_pos tests

my @p = $mcp->chord_pos( [ 0, 4, 7 ], -voices => 4 );

#my %conv = qw( 0 c 1 cis 2 d 3 cis 4 e 5 f 6 fis 7 g 8 gis 9 a 10 ais 11 b );
#my %regi = ( 0, ",", 1, "", 2, "'", 3, "''", 4, "'''" );
#for my $pr (@p) {
#  for my $n (@$pr) {
#    my $nn = $conv{$n%12};
#    my $r  = $regi{int($n/12)};
#    $n = $nn.$r;
#  }
#}
use Data::Dump qw(dump); diag "hmmm"; diag dump $_ for @p;
