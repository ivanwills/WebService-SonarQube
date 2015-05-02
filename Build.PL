use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
	module_name       => 'WebService::SonarQube',
	license           => 'perl',
	dist_author       => 'Ivan Wills <ivan.wills@gmail.com>',
	dist_version_from => 'lib/WebService/SonarQube.pm',
	requires          => {
		'perl'             => 5.008,
	},
	build_requires => {
		'Test::More'     => 0,
		'Test::Warnings' => 0,
	},
	add_to_cleanup     => [ 'WebService-SonarQube-*' ],
	create_makefile_pl => 'traditional',
	create_license     => 1,
	meta_merge => {
		resources => {
			repository => 'git://github.com/ivanwills/WebService-SonarQube.git',
			bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=WebService::SonarQube',
		},
	},
);

$builder->create_build_script();
