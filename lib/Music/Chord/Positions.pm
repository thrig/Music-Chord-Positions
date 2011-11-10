package Music::Chord::Positions;

use strict;
use warnings;

use parent qw(Music::Chord::Note);

our $VERSION = '0.01';

sub new {
  my ($class) = @_;
  $class->SUPER::new();
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
  my ( $self, $chord ) = @_;

  my @pitches = $self->SUPER::chord_num($chord);
  return @pitches;
}

# Preloaded methods go here.

1;
__END__

=head1 NAME

Music::Chord::Positions - Perl extension for blah blah blah

=head1 SYNOPSIS

  use Music::Chord::Positions;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for Music::Chord::Positions, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head1 SEE ALSO

L<Music::Chord::Note>

=head1 AUTHOR

Jeremy Mates E<lt>jmates@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Jeremy Mates

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself, either Perl version 5.14 or, at
your option, any later version of Perl 5 you may have available.

=cut
