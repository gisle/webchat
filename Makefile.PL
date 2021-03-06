use ExtUtils::MakeMaker;

WriteMakefile(
   NAME      => "webchat",
   VERSION   => "0.05",
   PREREQ_PM => {
		  'Data::Dump'   => '0.01',
                  'URI'          => '1.00',
		  'LWP'          => '5.47',
                },
   EXE_FILES => [ 'webchatpp' ],
   dist      => { COMPRESS => 'gzip -9f', SUFFIX => 'gz'},
);
