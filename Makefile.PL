use ExtUtils::MakeMaker;

WriteMakefile(
   NAME      => "webchat",
   VERSION   => "0.01",
   PREREQ_PM => {
                  'HTML::Parser' => '2.21',
		  'Data::Dump'   => '0.01',
                  'URI'          => '0.9003',
		  'LWP'          => '5.40',
                },
   EXE_FILES => [ 'webchatpp' ],
   dist      => { COMPRESS => 'gzip -9f', SUFFIX => 'gz'},
);