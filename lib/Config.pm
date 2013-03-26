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

package Bugzilla::Extension::OpenID::Config;
use strict;
use warnings;

use Bugzilla::Config::Common;

sub get_param_list {
    my ($class) = @_;

    my @param_list = (
    {
     name => 'openid_sso_enabled',
     type => 'b',
     default => '0'
    },
    {
     name => 'openid_sso_url',
     type => 't',
     default => ''
    }
    );
    return @param_list;
}

1;
