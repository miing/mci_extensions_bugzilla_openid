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

use constant NAME => 'OpenID';

use constant REQUIRED_MODULES => [
    {
        package => 'Net::OpenID::Consumer',
        module  => 'Net::OpenID::Consumer',
        version => 1.14,
    },
    {
        package => 'LWPx::ParanoidAgent',
        module  => 'LWPx::ParanoidAgent',
        version => 1.09,
    },
    {
        package => 'LWP::UserAgent',
        module  => 'LWP::UserAgent',
        version => 6.05,
    },
    {
        package => 'Cache::Cache',
        module  => 'Cache::Cache',
        version => 1.06,
    },
];

use constant OPTIONAL_MODULES => [
];

__PACKAGE__->NAME;
