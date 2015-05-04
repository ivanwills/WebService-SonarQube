package WebService::SonarQube;

# Created on: 2015-05-02 20:12:53
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use Moo;
use strict;
use warnings;
use Carp;
use namespace::clean;
use English qw/ -no_match_vars /;
use WWW::Mechanize;
use Type::Tiny;
use Types::Standard -types;
use URI;
use WWW::Mechanize;
use JSON;
use Try::Tiny;

our $VERSION = 0.01;

has url => (
    is       => 'rw',
    required => 1,
    isa      => Str,
);
has [qw/username password version/] => (
    is  => 'rw',
    isa => Str,
);
has mech => (
    is      => 'rw',
    default => sub { WWW::Mechanize->new(); },
);
has commands => (
    is => 'rw',
);

sub BUILD {
    my ($self) = @_;

    $self->mech->add_header(accept => 'application/json');

    if ($self->url =~ m{/$}) {
        my $url = $self->url;
        $url =~ s{/$}{};
        $self->url($url);
    }

    $self->_get_commands();

    my $server = $self->_get('server/index');
    $self->version($server->{version});
}

sub _get_commands {
    my ($self) = @_;

    my $list = $self->_get('webservices/list',  include_internals => 'true');

    my %commands;
    for my $ws (@{ $list->{webServices}}) {
        my $name = $ws->{path};
        $name =~ s{^api/}{};

        for my $action (@{ $ws->{actions} }) {
            $commands{$name . '/' . $action->{key}} = {
                name     => $name . '_' . $action->{key},
                url      => $name . '/' . $action->{key},
                internal => !!$action->{internal},
                post     => !!$action->{post},
            };
        }
    }

    $self->commands(\%commands);
}

our $AUTOLOAD;
sub AUTOLOAD {
    my ($self, %params) = shift;

    my $api =  $AUTOLOAD;
    $api =~ s{.*::}{};
    $api =~ s{_}{/}g;

    if (!$self->commands->{$api}) {
        confess "Unknown command $api for SonarQube " . $self->version . '!';
    }

    my $result;
    try {
        $result = $self->_get($api, %params);
    }
    catch {
        confess "Errored trying $AUTOLOAD()\n$_\n";
    };

    return $result;
}

sub _get {
    my ($self, $api, %params) = @_;

    my $mech = $self->mech;
    my $uri = URI->new($self->url . '/api/' . $api);
    $uri->query_form(%params);

    $mech->get($uri);

    return decode_json($mech->content || '{}');
}

1;

__END__

=head1 NAME

WebService::SonarQube - API for talking to SonarQube

=head1 VERSION

This documentation refers to WebService::SonarQube version 0.01

=head1 SYNOPSIS

   use WebService::SonarQube;

   # create a new object
   my $sonar = WebService::SonarQube->new(
       url => 'http://example.com/sonar',
   );

   # call a sonar api
   my $server_details = $sonar->server_index();

=head1 DESCRIPTION

Simple interface to accessing SonarQube's web API.

=head1 SUBROUTINES/METHODS

POST api/action_plans/close
POST api/action_plans/create
POST api/action_plans/delete
POST api/action_plans/open
 GET api/action_plans/search
POST api/action_plans/update
 GET api/authentication/validate
 GET api/coverage/show
 GET api/duplications/show
 GET api/events/index
 GET api/favorites/index
 GET api/issue_filters/favorites
 GET api/issue_filters/show
POST api/issues/add_comment
POST api/issues/assign
 GET api/issues/authors
POST api/issues/bulk_change
 GET api/issues/changelog
POST api/issues/create
POST api/issues/delete_comment
POST api/issues/do_action
POST api/issues/do_transition
POST api/issues/edit_comment
POST api/issues/plan
 GET api/issues/search
POST api/issues/set_severity
 GET api/languages/list
 GET api/manual_measures/index
 GET api/metrics/index
POST api/permissions/add
POST api/permissions/remove
POST api/profiles/backup
POST api/profiles/destroy
 GET api/profiles/index
 GET api/profiles/list
POST api/profiles/restore
POST api/profiles/set_as_default
POST api/projects/create
POST api/projects/destroy
 GET api/projects/index
 GET api/properties/index
POST api/qualitygates/copy
POST api/qualitygates/create
POST api/qualitygates/create_condition
POST api/qualitygates/delete_condition
POST api/qualitygates/deselect
POST api/qualitygates/destroy
 GET api/qualitygates/list
POST api/qualitygates/rename
 GET api/qualitygates/search
POST api/qualitygates/select
POST api/qualitygates/set_as_default
 GET api/qualitygates/show
POST api/qualitygates/unset_default
POST api/qualitygates/update_condition
POST api/qualityprofiles/activate_rule
POST api/qualityprofiles/activate_rules
POST api/qualityprofiles/deactivate_rule
POST api/qualityprofiles/deactivate_rules
POST api/qualityprofiles/restore_built_in
 GET api/resources/index
POST api/rules/create
POST api/rules/delete
 GET api/rules/repositories
 GET api/rules/search
 GET api/rules/show
 GET api/rules/tags
POST api/rules/update
 GET api/server/index
POST api/server/setup
 GET api/sources/raw
 GET api/sources/scm
 GET api/sources/show
 GET api/system/info
POST api/system/restart
 GET api/tests/covered_files
 GET api/tests/show
 GET api/tests/test_cases
 GET api/timemachine/index
 GET api/updatecenter/installed_plugins
 GET api/user_properties/index
POST api/users/create
POST api/users/deactivate
 GET api/users/search
POST api/users/update
POST api/views/add_local_view
POST api/views/add_project
POST api/views/add_remote_view
POST api/views/add_sub_view
POST api/views/create
 GET api/views/define
POST api/views/delete
 GET api/views/list
 GET api/views/local_views
POST api/views/manual_measure
POST api/views/mode
POST api/views/move
 GET api/views/move_options
 GET api/views/projects
POST api/views/regexp
 GET api/views/remote_views
POST api/views/remove_project
 GET api/views/show
POST api/views/update
 GET api/webservices/list
 GET api/webservices/response_example

=head1 DIAGNOSTICS

A list of every error and warning message that the module can generate (even
the ones that will "never happen"), with a full explanation of each problem,
one or more likely causes, and any suggested remedies.

=head1 CONFIGURATION AND ENVIRONMENT

A full explanation of any configuration system(s) used by the module, including
the names and locations of any configuration files, and the meaning of any
environment variables or properties that can be set. These descriptions must
also include details of any configuration language used.

=head1 DEPENDENCIES

A list of all of the other modules that this module relies upon, including any
restrictions on versions, and an indication of whether these required modules
are part of the standard Perl distribution, part of the module's distribution,
or must be installed separately.

=head1 INCOMPATIBILITIES

A list of any modules that this module cannot be used in conjunction with.
This may be due to name conflicts in the interface, or competition for system
or program resources, or due to internal limitations of Perl (for example, many
modules that use source code filters are mutually incompatible).

=head1 BUGS AND LIMITATIONS

A list of known problems with the module, together with some indication of
whether they are likely to be fixed in an upcoming release.

Also, a list of restrictions on the features the module does provide: data types
that cannot be handled, performance issues and the circumstances in which they
may arise, practical limitations on the size of data sets, special cases that
are not (yet) handled, etc.

The initial template usually just has:

There are no known bugs in this module.

Please report problems to Ivan Wills (ivan.wills@gmail.com).

Patches are welcome.

=head1 AUTHOR

Ivan Wills - (ivan.wills@gmail.com)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2015 Ivan Wills (14 Mullion Close, Hornsby Heights, NSW Australia 2077).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
