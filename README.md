# OpenID for Bugzilla

Integrates OpenID Authentication with Bugzilla

***

## Features

OpenID for Bugzilla for now has already offered these functionality:

 - OpenID standard support
 	 * OpenID 2.0
 	 * OpenID 1.0

 - OpenID selector with editable OpenID Url
     * One click to what you choose
     * Input OpenID Url you already trust

 - OpenID SSO (Single Sign on)
     * Integration with certain OpenID provider or the one you own
     

## Dependencies

Before firing OpenID Auth up with your site, one thing you need to do is
make these modules installed first, as listed below:

 - Net::OpenID::Consumer
 - LWPx::ParanoidAgent
 - LWP::UserAgent
 - Cache::FileCache

For more information, take a look at http://search.cpan.org/.


## Installation

Pretty straightforward, for installation, so only follow the following:

	git clone git://github.com/miing/mci_extensions_bugzilla_OpenID.git OpenID
	cp -rf OpenID /path/to/your/bugzilla/extensions


## Configuration

After installing successfully, in order to enable it, go through with these following 
steps with your admin account on bugzilla site:

 - "admin account" ==> "Administration" ==> "Parameters" ==> "User Authentication" ==> "user_info_class with "OpenID,CGI" ==> "Save Changes"

If you would like to get the way which is exactly called OpenID SSO, then follow the one:

 - "admin account" ==> "Administration" ==> "Parameters" ==> "OpenID" ==> "openid_sso_enabled with 'on'" ==> "Input your OpenID Url for SSO" ==> "Save Changes"


## References

 - http://search.cpan.org/~wrog/Net-OpenID-Consumer-1.14/
 - http://search.cpan.org/~saxjazman/LWPx-ParanoidAgent/
 - http://search.cpan.org/~gaas/libwww-perl-6.05/
 - http://search.cpan.org/~jswartz/Cache-Cache-1.06/
 - http://openid.net/developers/specs/
 - https://bugzilla.mozilla.org/show_bug.cgi?id=294608
 - http://openid.net/developers/libraries/
 - http://openid.net/add-openid/add-getting-started/
 - http://openid.net/specs/openid-attribute-exchange-1_0.html
 - http://www.lifewiki.net/openid/OpenIDSpecification
 - http://www.lifewiki.net/openid/OpenIDConsumers
 - https://wiki.mozilla.org/Bugzilla:OpenID_Auth_Plugin
 - http://www.lemoda.net/perl/openid/net-openid.html
 - http://www.peterbe.com/plog/openid-attribute-exchange-sreg-and-google
 - https://developers.google.com/accounts/docs/OpenID
 
 
***
 
# Author

Samuel Mi <samuel.miing@gmail.com> from Miing.org
