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


package Bugzilla::Extension::OpenID::Login;
use strict;
use base qw(Bugzilla::Auth::Login);

use Bugzilla::Constants;
use Bugzilla::Util;
use Bugzilla::Error;

use Cache::File;
use LWPx::ParanoidAgent;
use Net::OpenID::Consumer;

use constant requires_verification   => 0;
use constant is_automatic            => 1;
use constant user_can_create_account => 0;

sub get_login_info {
    my ($self) = @_;
    
    # Collect CGI Parameters
    my $cgi = Bugzilla->cgi;
    my $opurl = $cgi->param('openid_identifier');
    
    # security: don't pass through sensitive info
    $cgi->delete('openid_identifier');
    if (!$opurl) { 
        return { failure => AUTH_NODATA };	
	}
    
    # Collect OpenID Parameters
    my $o_ref = _collect_openid_params($cgi);
    my @openid_keys = @{$o_ref->{keys}};
    my %openid_p = %{$o_ref->{params}};
    
    # Call OpenID Provider for login
	my $openid_ret = _openid_provider_login($cgi, $opurl, $o_ref);
    
    # Check return conditions from OpenID Provider
    if ($openid_ret->{redirected}) {
        # Arriving here means a redirect command has been output before this.
        # Therefore, let it happen.
        return;
    }
    
    if (!exists $openid_ret->{vident}) {
        return { failure => AUTH_ERROR, 
		         error => 'openid_login_error', };
    }
    
    # Get user info from OpenID provider
    my ($email, $fullname, $nickname );
    {
        my $userinfo = _collect_openid_userinfo($openid_ret->{vident});
        $email = $userinfo->{email};
        $fullname = $userinfo->{fullname};
        $nickname = $userinfo->{nickname};
    }
    
    # Check if all required user info exists there
    if (!$email) {
        # security: don't pass through sensitive info
		$cgi->delete('openid_identifier', @openid_keys);
		    
		# OpenID Consumer library yet to be installed there
		return { failure => AUTH_ERROR, 
		         error => 'openid_userinfo_error' };
    }
    
    # Put all user info altogether and try creating or updating the user
    my $login_data = {
        'username' => $email
    };
    my $result = Bugzilla::Auth::Verify->create_or_update_user($login_data);
    return $result if $result->{'failure'};
    
    # You can restrict people in a particular group from logging in using
    # OpenID by making that group a member of a group called
    # "no-openid".
    #
    # If you have your "createemailregexp" set up in such a way that a
    # newly-created account is a member of "no-openid", this code will
    # create an account for them and then fail their login. Which isn't
    # great, but they can still use normal-Bugzilla-login password 
    # recovery.
    my $user = $result->{'user'};
    if ($user->in_group('no-openid')) {
        # We use a custom error here, for greater clarity, rather than
        # returning a failure code.
        ThrowUserError('openid_account_too_powerful');
    }
    $login_data->{'user'} = $user;
    $login_data->{'user_id'} = $user->id;
    
    return $login_data;
}


# Copied from Bugzilla::Extensions::BrowserID::Auth::Login
sub fail_nodata {
    my ($self) = @_;
    my $cgi = Bugzilla->cgi;
    my $template = Bugzilla->template;

    if (Bugzilla->usage_mode != Bugzilla::Constants->USAGE_MODE_BROWSER) {
        ThrowUserError('login_required');
    }

    print $cgi->header();

    $template->process("account/auth/login.html.tmpl",
                       { 'target' => $cgi->url(-relative=>1) })
        || ThrowTemplateError($template->error());
    exit;
}

# Login to OpenID provider 
sub _openid_provider_login {
    my $cgi = shift;
    my $opurl = shift;
    my $o_ref = shift;
    my @openid_keys = @{$o_ref->{keys}};
    my %openid_p = %{$o_ref->{params}};
	my %result;
	
	# Get OpenID configuration info
	#my $cache = Cache::FileCache->new({namespace => 'OpenIDExtension'});
	my $nonce_pattern = "GJvxv_%s";
    my $consumer_secret = sub { sprintf($nonce_pattern, shift^0xCAFEFEED) };
    my $urlbase = correct_urlbase();
    my $required_root = $urlbase;
    my $return_to = $urlbase . "index.cgi?GoAheadAndLogIn=1\&openid_identifier=$opurl";
    my $trust_root = $urlbase;
    
    # Here we at first would like to try resolving response from this OpenID provider
    # specified. If that's not present, then we will raise a request for the OpenID 
    # provider.
    if (exists $openid_p{mode}) {
        #ThrowCodeError('openid.mode=' . $openid_p{mode});
        # found OpenID parameters so process response from OpenID provider
		my $csr = Net::OpenID::Consumer->new(
			#cache => $cache,
			args  => $cgi,
			consumer_secret => $consumer_secret,
			required_root => $required_root,
		);
		if (!$csr) {
		    # security: don't pass through sensitive info
		    $cgi->delete('openid_identifier', @openid_keys);
		    
		    # OpenID Consumer library yet to be installed there
		    return { failure => AUTH_ERROR, 
		             error => 'openid_init_error' };
		}

		# handle responses
		if (my $setup_url = $csr->user_setup_url) {
		    # security: don't pass through sensitive info
			$cgi->delete('openid_identifier', @openid_keys);
				
			# OpenID request failed, requiring user to perform setup.
			# In this case, automatically redirect user to OpenID provider.
			ThrowCodeError('setup.' . $setup_url);
		    print $cgi->redirect($setup_url);
		    $result{redirected} = 1;
		}
		elsif ($csr->user_cancel) {
		    # security: don't pass through sensitive info
			$cgi->delete('openid_identifier', @openid_keys);
			
			# Automatically redirect user back to front page on your site 
			# if OpenID request is canceled by user from OpenID provider.
			print $cgi->redirect($required_root);
			$result{redirected} = 1;
		}
		elsif (my $vident = $csr->verified_identity) {
		    #ThrowCodeError("viden." . $vident);
		    if (!defined $vident) {
		        # security: don't pass through sensitive info
			    $cgi->delete('openid_identifier', @openid_keys);
			
		        return { failure => AUTH_ERROR, 
		                 error => 'openid_response_error',
		                 details => {errcode => $csr->errcode(), 
		                             errtext => $csr->errtext()} };
		    }
		    
		    # Up until this point, login successfully
		    $result{vident} = $vident;
		    ThrowCodeError('result{vident}=' . $result{vident});
		}
		else {
		    # security: don't pass through sensitive info
		    $cgi->delete('openid_identifier', @openid_keys);
			    
			# Here is a place capturing and dealing with all errors in responses
			# provided by OpenID provider.
		    return { failure => AUTH_ERROR, 
		             error => 'openid_response_error',
		             details => {errcode => $csr->errcode(), 
		                         errtext => $csr->errtext()} };
		}
	} 
	elsif ((defined $opurl) && length($opurl)) {
	    # Submit a request from OpenID enabled site into OpenID provider, 
	    # if there are no any responses arriving here.
	    my $csr = Net::OpenID::Consumer->new(
	        ua => LWPx::ParanoidAgent->new,
			#cache => $cache,
			args => $cgi,
			consumer_secret => $consumer_secret,
			required_root => $required_root,
		);
		if (!$csr) {
		    # security: don't pass through sensitive info
		    $cgi->delete('openid_identifier', @openid_keys);
		    
		    # OpenID Consumer library yet to be installed there
		    return { failure => AUTH_ERROR, 
		             error => 'openid_init_error' };
		}
		
		# Find out OpenID provider specified by user-entered URL, 
		# but authenticated between user and OpenID provider. And then,
		# redirect to the OpenID provider that have already been found there
		# to eventually perform authentication.
		my $cident = $csr->claimed_identity($opurl);
        if (defined $cident) {
            my $version = $cident->protocol_version;
            if ($version == 2) {
                #ThrowCodeError('version=' . $version);
                # OpenID version 2.0 with AX (Attribute Exchange)
                $cident->set_extension_args(
                    'http://openid.net/srv/ax/1.0',
                    {
                        mode => 'fetch_request',
                        #required => 'email',
                        required => 'email, firstname, lastname',
                        'type.email' => 'http://axschema.org/contact/email',
                        'type.firstname' => 'http://axschema.org/namePerson/first',
                        'type.lastname' => 'http://axschema.org/namePerson/last',
                    },
                );
            }
            else {
                # OpenID version 1.1 with SREG (Simple Registration) 
                $cident->set_extension_args(
                    'http://openid.net/extensions/sreg/1.1',
                    {
                        required => 'email',
                        optional => 'fullname, nickname',
                    },
                );
            }
            my $check_url = $cident->check_url(
                # The place we go back to
                return_to => $return_to,
                trust_root => $trust_root,
                delayed_return => 1,
            );
            
            # Automatically redirect user to OpenID provider specified
            #ThrowCodeError('check_url.' . $check_url);
            print $cgi->redirect($check_url);
            $result{redirected} = 1;
        }
        else {
            # security: don't pass through sensitive info
		    $cgi->delete('openid_identifier', @openid_keys);
			    
			# Here is a place capturing and dealing with all errors in requests
			# provided by OpenID provider.
		    return { failure => AUTH_ERROR, 
		             error => 'openid_request_error',
		             details => {errcode => $csr->errcode(), 
		                         errtext => $csr->errtext()} };
        }
	}
	
	return \%result;
}

# Extract OpenID parameters from Bugzilla CGI
sub _collect_openid_params {
    my $cgi = shift;
	my $cgiparams = $cgi->Vars;

    my @openid_keys = grep(/^openid\./, keys %$cgiparams);
    my %openid_p;
    foreach my $p (@openid_keys) {
	if ($p =~ /^openid\.(.*)/) {
	    my $p_suffix = $1;
            my $val = $cgi->param($p);
            if (defined $val) {
                $openid_p{$p_suffix} = $val;
            }
		}
    }

	return {keys => \@openid_keys, params => \%openid_p};
}

# Get OpenID user info via SREG or AX
sub _collect_openid_userinfo {
    my $vident = shift;
	my %result;
	
	# collect user info from OpenID Provider
	my $ax = $vident->signed_extension_fields('http://openid.net/srv/ax/1.0');
	my $sreg = $vident->signed_extension_fields('http://openid.net/extensions/sreg/1.1');
	if (exists $ax->{'value.email'}) {
		# OpenID 2.0 AX (Attribute eXchange)
		$result{email} = ((exists $ax->{'value.email'})
			? $ax->{'value.email'} : "" );
		$result{firstname} = ((exists $ax->{'value.firstname'})
			? $ax->{'value.firstname'} : "" );
	    $result{lastname} = ((exists $ax->{'value.lastname'})
			? $ax->{'value.lastname'} : "" );
		if (exists $result{firstname} || exists $result{lastname}) {
		    $result{fullname}
		        = join(' ', $result{firstname}, $result{lastname});
		}
	} 
	else {
		# OpenID 1.1 SREG (Simple REGistration)
		$result{email} = $sreg->{email};
		$result{fullname} = $sreg->{fullname};
		$result{nickname} = $sreg->{nickname};
	}
	return \%result;
}

1;
