use ExtUtils::MakeMaker;

my %params = (
  NAME         => 'Music::Chord::Positions',
  VERSION_FROM => 'lib/Music/Chord/Positions.pm',
  LICENSE      => 'perl',
  PREREQ_PM    => {
    Carp               => 0,
    List::MoreUtils    => 0,
    List::Util         => 0,
    Music::Chord::Note => 0,    # nice to have, but not essential
    Test::More         => 0,
  },
  ( $] >= 5.005
    ?    ## Add these new keywords supported since 5.005
      (
      ABSTRACT_FROM =>
        'lib/Music/Chord/Positions.pm',    # retrieve abstract from module
      AUTHOR => 'Jeremy Mates <jmates@cpan.org>'
      )
    : ()
  ),
);

if ( $ExtUtils::MakeMaker::VERSION ge '6.46' ) {
  $parms{META_MERGE} = {
    resources => {
      license    => 'http://dev.perl.org/licenses/artistic.html',
      repository => 'http://github.com/thrig/Music-Chord-Positions',
      bugtracker =>
        'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Music-Chord-Positions',
    }
  };
}

WriteMakefile(%params);
