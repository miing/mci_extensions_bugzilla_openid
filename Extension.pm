# -*- Mode: perl; indent-tabs-mode: nil -*-
#
# The contents of this file are subject to the Mozilla Public
# License Version 1.1 (the "License"); you may not use this file
# except in compliance with the License. You may obtain a copy of
# the License at http://www.mozilla.org/MPL/
#
# Software distributed under the License is distributed on an "AS
# IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or
# implied. See the License for the specific language governing
# rights and limitations under the License.
#
# The Original Code is the OpenID Bugzilla Extension.
#
# Copyright (C) 2013 Miing.org. All Rights Reserved.
#
# Contributor(s):
#   Miing.org <samuel.miing@gmail.com>

package Bugzilla::Extension::OpenID;
use strict;
use base qw(Bugzilla::Extension);

our $VERSION = '1.0';

sub auth_login_methods {
    my ($self, $args) = @_;
    my $modules = $args->{'modules'};
    if (exists($modules->{'OpenID'})) {
        $modules->{'OpenID'} = 'Bugzilla/Extension/OpenID/Login.pm';
    }
}

sub config_modify_panels {
    my ($self, $args) = @_;
    my $panels = $args->{'panels'};
    my $auth_panel_params = $panels->{'auth'}->{'params'};

    my ($user_info_class) =
                grep { $_->{'name'} eq 'user_info_class' } @$auth_panel_params;

    if ($user_info_class) {
        push(@{ $user_info_class->{'choices'} }, "OpenID,CGI");
    }
}

sub config_add_panels {
    my ($self, $args) = @_;

    my $modules = $args->{'panel_modules'};
    $modules->{'OpenID'} = "Bugzilla::Extension::OpenID::Config";
}

__PACKAGE__->NAME;
