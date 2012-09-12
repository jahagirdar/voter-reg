use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'smartVote',
    AUTHOR              => q{YOUR NAME <jahagirdar.vs@gmail.com>},
    VERSION_FROM        => 'lib/smartVote.pm',
    ABSTRACT            => 'Bulk Voter Registeration',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'YAML'       => 0,
        'Dancer'     => 1.3099,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'smartVote-*' },
);
