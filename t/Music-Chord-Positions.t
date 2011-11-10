use strict;
use warnings;

use Test::More tests => 4;
BEGIN { use_ok('Music::Chord::Positions') }

can_ok( 'Music::Chord::Positions', qw/new/ );

my $mcp = Music::Chord::Positions->new();

# Check that parent behaves as expected, breakage here would indicate
# Music::Chord::Note has changed interface since 0.0.6.
{
  isa_ok( $mcp, 'Music::Chord::Note' );

  is( join( q{,}, $mcp->chord_num() ),
    '0,4,7', 'check chord_num from parent' );
}
