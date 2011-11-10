use ExtUtils::MakeMaker;

my %params = (
  NAME         => 'Music::Chord::Positions',
  VERSION_FROM => 'lib/Music/Chord/Positions.pm',  # finds $VERSION
  PREREQ_PM    => { Music::Chord::Note => 0.0.6 }, # e.g., Module::Name => 1.1
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
